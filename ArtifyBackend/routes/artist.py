# routes/artist.py

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware

from models.artist import Artist
from models.song import Song
from models.album import Album
from models.songArtist import SongArtist, SongArtistRole
from models.albumArtist import AlbumArtist

from schemas.artist import ArtistCreate, ArtistUpdate, ArtistOut

router = APIRouter(
    tags=["artists"],
)

# ---------- UTILITY ----------

def _get_artist_or_404(artist_id: str, db: Session) -> Artist:
    artist = (
        db.query(Artist)
        .options(
            joinedload(Artist.songs),
            joinedload(Artist.albums),
        )
        .filter(Artist.id == artist_id)
        .first()
    )
    if not artist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artist not found",
        )
    return artist

def _resolve_songs(db: Session, song_ids: List[str]) -> List[Song]:
    if not song_ids:
        return []
    songs = db.query(Song).filter(Song.id.in_(song_ids)).all()
    if len(songs) != len(set(song_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some song IDs do not exist",
        )
    return songs

# ---------- GET SINGOLO ARTISTA ----------

@router.get(
    "/{artist_id}",
    response_model=ArtistOut,
)
def get_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    return _get_artist_or_404(artist_id, db)

# ---------- LISTA ARTISTI ----------

@router.get(
    "",   # GET /artist/
    response_model=List[ArtistOut],
)
def list_artists(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Restituisce TUTTI gli artisti, senza filtri.
    """
    artists = (
        db.query(Artist)
        .options(
            joinedload(Artist.songs),
            joinedload(Artist.albums),
        )
        .order_by(Artist.name.asc())
        .all()
    )
    return artists

# ---------- SEARCH / FILTER ARTISTI ----------

@router.get(
    "/search",   # GET /artist/search
    response_model=List[ArtistOut],
)
def search_artists(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
    q: Optional[str] = None,
    song_id: Optional[str] = None,
    album_id: Optional[str] = None,
):
    """
    Ricerca / filtro artisti.

    Filtri opzionali:
    - `q`: match case-insensitive su name / display_name
    - `song_id`: solo artisti collegati a quella song
    - `album_id`: solo artisti collegati a quell'album
    """
    query = (
        db.query(Artist)
        .options(
            joinedload(Artist.songs),
            joinedload(Artist.albums),
        )
    )

    if q:
        pattern = f"%{q.lower()}%"
        query = query.filter(
            (Artist.name.ilike(pattern)) |
            (Artist.display_name.ilike(pattern))
        )

    if song_id:
        query = query.join(Artist.songs).filter(Song.id == song_id)

    if album_id:
        query = query.join(Artist.albums).filter(Album.id == album_id)

    artists = query.all()
    return artists


def _resolve_albums(db: Session, album_ids: List[str]) -> List[Album]:
    if not album_ids:
        return []
    albums = db.query(Album).filter(Album.id.in_(album_ids)).all()
    if len(albums) != len(set(album_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some album IDs do not exist",
        )
    return albums

# ---------- CREATE ARTIST ----------

@router.post(
    "",   # 👈 nota lo slash
    status_code=status.HTTP_201_CREATED,
    response_model=ArtistOut,
)
def create_artist(
    payload: ArtistCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    artist_id = str(uuid.uuid4())

    songs = _resolve_songs(db, payload.song_ids)
    albums = _resolve_albums(db, payload.album_ids)

    db_artist = Artist(
        id=artist_id,
        name=payload.name,
        display_name=payload.display_name,
        slug=payload.slug,
        image_url=payload.image_url,
        bio=payload.bio,
        country=payload.country,
    )

    db_artist.song_artist_links = [
        SongArtist(
            id=str(uuid.uuid4()),
            song=song,
            artist=db_artist,
            role=SongArtistRole.PRIMARY,
        )
        for song in songs
    ]

    db_artist.album_artist_links = [
        AlbumArtist(
            id=str(uuid.uuid4()),
            album=album,
            artist=db_artist,
            role=None,
        )
        for album in albums
    ]

    db.add(db_artist)
    db.commit()

    db_artist = _get_artist_or_404(artist_id, db)
    return db_artist

# ---------- UPDATE ARTIST ----------

@router.patch(
    "/{artist_id}",
    response_model=ArtistOut,
)
def update_artist(
    artist_id: str,
    payload: ArtistUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    artist = _get_artist_or_404(artist_id, db)

    if payload.name is not None:
        artist.name = payload.name
    if payload.display_name is not None:
        artist.display_name = payload.display_name
    if payload.slug is not None:
        artist.slug = payload.slug
    if payload.image_url is not None:
        artist.image_url = payload.image_url
    if payload.bio is not None:
        artist.bio = payload.bio
    if payload.country is not None:
        artist.country = payload.country

    if payload.song_ids is not None:
        songs = _resolve_songs(db, payload.song_ids)
        artist.song_artist_links.clear()
        for song in songs:
            artist.song_artist_links.append(
                SongArtist(
                    id=str(uuid.uuid4()),
                    song=song,
                    artist=artist,
                    role=SongArtistRole.PRIMARY,
                )
            )

    if payload.album_ids is not None:
        albums = _resolve_albums(db, payload.album_ids)
        artist.album_artist_links.clear()
        for album in albums:
            artist.album_artist_links.append(
                AlbumArtist(
                    id=str(uuid.uuid4()),
                    album=album,
                    artist=artist,
                    role=None,
                )
            )

    db.commit()
    artist = _get_artist_or_404(artist_id, db)
    return artist

# ---------- DELETE ARTIST ----------

@router.delete(
    "/{artist_id}",
    status_code=status.HTTP_200_OK,
)
def delete_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    artist = db.query(Artist).filter(Artist.id == artist_id).first()
    if not artist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artist not found",
        )

    db.delete(artist)
    db.commit()
    return {"message": "Artist deleted successfully"}
