import mimetypes
import uuid
from typing import List, Optional

import cloudinary
import cloudinary.uploader
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session, joinedload

from core.config import settings
from database import get_db
from middleware.auth_middleware import auth_middleware

from models.album import Album
from models.artist import Artist
from models.song import Song
from models.user import User  # Importante per il check dei permessi
from models.albumArtist import AlbumArtist
from models.albumSong import AlbumSong
from models.songArtist import SongArtist, SongArtistRole

from schemas.album_schema import AlbumCreate, AlbumUpdate, AlbumOut

router = APIRouter(tags=["albums"])

# Configurazione Cloudinary (già ok)
cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)

# ---------- UTILITIES DI SICUREZZA ----------

def _get_user_artist_or_404(user_id: str, db: Session) -> Artist:
    """Verifica che l'utente sia un artista e restituisce il suo profilo."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.artist_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo gli utenti con un profilo artista possono gestire album."
        )
    return user.artist_profile

def _check_album_ownership(album: Album, artist_id: str):
    """Verifica che l'artista corrente faccia parte degli artisti dell'album."""
    artist_ids = [a.id for a in album.artists]
    if artist_id not in artist_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Non hai i permessi per modificare questo album."
        )

def _get_album_or_404(album_id: str, db: Session) -> Album:
    album = (
        db.query(Album)
        .options(
            joinedload(Album.artists),
            joinedload(Album.songs),
        )
        .filter(Album.id == album_id)
        .first()
    )
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    return album

def _resolve_artists(db: Session, artist_ids: List[str]) -> List[Artist]:
    if not artist_ids: return []
    artists = db.query(Artist).filter(Artist.id.in_(artist_ids)).all()
    if len(artists) != len(set(artist_ids)):
        raise HTTPException(status_code=400, detail="Uno o più ID artista non validi.")
    return artists

def _resolve_songs(db: Session, song_ids: List[str]) -> List[Song]:
    if not song_ids: return []
    songs = db.query(Song).filter(Song.id.in_(song_ids)).all()
    if len(songs) != len(set(song_ids)):
        raise HTTPException(status_code=400, detail="Uno o più ID canzone non validi.")
    return songs


# ---------- ROUTES ----------

@router.post("/upload-cover", status_code=status.HTTP_201_CREATED)
async def upload_album_cover(
    cover: UploadFile = File(...),
    auth_details: dict = Depends(auth_middleware),
    db: Session = Depends(get_db)
):
    # Blindaggio 1: Solo gli artisti caricano cover
    _get_user_artist_or_404(auth_details['uid'], db)

    content_type = cover.content_type
    if not (content_type and content_type.startswith("image/")):
        raise HTTPException(status_code=400, detail="File non valido. Carica un'immagine.")

    try:
        upload_res = cloudinary.uploader.upload(
            cover.file,
            folder=f"artify/albums/covers",
        )
        return {"cover_url": upload_res["url"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("", status_code=status.HTTP_201_CREATED, response_model=AlbumOut)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    # Blindaggio 2: Check identità e transazione atomica
    current_artist = _get_user_artist_or_404(auth_details['uid'], db)
    
    # Assicuriamoci che l'artista che crea l'album sia incluso negli artist_ids
    if current_artist.id not in payload.artist_ids:
        payload.artist_ids.append(current_artist.id)

    try:
        album_id = str(uuid.uuid4())
        
        # 1. Risoluzione entità
        album_artists = _resolve_artists(db, payload.artist_ids)
        existing_songs = _resolve_songs(db, payload.song_ids)
        
        # 2. Creazione Album
        db_album = Album(
            id=album_id,
            title=payload.title,
            release_date=payload.release_date,
            label=payload.label,
            album_type=payload.album_type,
            genre=payload.genre,
            cover_url=payload.cover_url,
        )
        db.add(db_album)

        # 3. Gestione Nuove Canzoni Inline
        all_songs_ordered = []
        
        # Aggiungiamo le esistenti (mantenendo l'ordine del payload)
        song_map = {s.id: s for s in existing_songs}
        all_songs_ordered.extend([song_map[sid] for sid in payload.song_ids])

        for track in payload.new_songs:
            new_song = Song(
                id=str(uuid.uuid4()),
                song_name=track.song_name,
                song_url=track.song_url,
                thumbnail_url=track.thumbnail_url or payload.cover_url,
                release_date=track.release_date or payload.release_date,
                genre=track.genre or payload.genre,
                # Blindaggio: la canzone appartiene all'utente che la sta creando
                user_id=auth_details['uid'] 
            )
            db.add(new_song)
            all_songs_ordered.append(new_song)
            
            # Link Artisti alla nuova canzone
            track_artist_ids = track.artist_ids or payload.artist_ids
            resolved_track_artists = _resolve_artists(db, track_artist_ids)
            for art in resolved_track_artists:
                role = track.artist_roles.get(art.id, SongArtistRole.PRIMARY)
                db.add(SongArtist(id=str(uuid.uuid4()), song=new_song, artist=art, role=role))

        # 4. Creazione Link Album-Artist e Album-Song
        db_album.album_artist_links = [
            AlbumArtist(id=str(uuid.uuid4()), album=db_album, artist=a) for a in album_artists
        ]
        
        db_album.album_song_links = [
            AlbumSong(id=str(uuid.uuid4()), album=db_album, song=s, track_number=i+1)
            for i, s in enumerate(all_songs_ordered)
        ]
        
        db_album.total_tracks = len(all_songs_ordered)

        db.commit()
        return _get_album_or_404(album_id, db)

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Errore creazione album: {str(e)}")


@router.patch("/{album_id}", response_model=AlbumOut)
def update_album(
    album_id: str,
    payload: AlbumUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    # Blindaggio 3: Solo chi "possiede" l'album può editarlo
    current_artist = _get_user_artist_or_404(auth_details['uid'], db)
    album = _get_album_or_404(album_id, db)
    _check_album_ownership(album, current_artist.id)

    try:
        # Aggiornamento campi base
        for field, value in payload.dict(exclude_unset=True).items():
            if field not in ['artist_ids', 'song_ids']:
                setattr(album, field, value)

        # Aggiornamento relazioni (se fornite)
        if payload.artist_ids is not None:
            artists = _resolve_artists(db, payload.artist_ids)
            album.album_artist_links.clear()
            for a in artists:
                album.album_artist_links.append(AlbumArtist(id=str(uuid.uuid4()), album=album, artist=a))

        if payload.song_ids is not None:
            songs = _resolve_songs(db, payload.song_ids)
            song_map = {s.id: s for s in songs}
            ordered = [song_map[sid] for sid in payload.song_ids]
            
            album.album_song_links.clear()
            for i, s in enumerate(ordered):
                album.album_song_links.append(AlbumSong(id=str(uuid.uuid4()), album=album, song=s, track_number=i+1))
            album.total_tracks = len(ordered)

        db.commit()
        return _get_album_or_404(album_id, db)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{album_id}")
def delete_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    # Blindaggio 4: Solo i proprietari cancellano
    current_artist = _get_user_artist_or_404(auth_details['uid'], db)
    album = _get_album_or_404(album_id, db)
    _check_album_ownership(album, current_artist.id)

    try:
        db.delete(album)
        db.commit()
        return {"message": "Album eliminato con successo."}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# GET routes rimangono simili ma aggiungiamo la protezione auth_middleware
@router.get("/{album_id}", response_model=AlbumOut)
def get_album(album_id: str, db: Session = Depends(get_db), auth_details: dict = Depends(auth_middleware)):
    return _get_album_or_404(album_id, db)