# routes/album.py

import uuid
from typing import List, Optional

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware

from models.album import Album
from models.artist import Artist
from models.song import Song
from models.albumArtist import AlbumArtist      # 👈 importa la join
from models.albumSong import AlbumSong          # 👈 importa la join

from schemas.album import (
    AlbumCreate,
    AlbumUpdate,
    AlbumOut,
)

router = APIRouter(tags=["albums"])


# ---------- UTILITY INTERNA ----------

def _get_album_or_404(album_id: str, db: Session) -> Album:
    album = (
        db.query(Album)
        .options(
            joinedload(Album.artists),  # usa la M:N viewonly
            joinedload(Album.songs),
        )
        .filter(Album.id == album_id)
        .first()
    )

    if not album:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )
    return album


def _resolve_artists(
    db: Session,
    artist_ids: List[str],
) -> List[Artist]:
    if not artist_ids:
        return []

    artists = (
        db.query(Artist)
        .filter(Artist.id.in_(artist_ids))
        .all()
    )

    if len(artists) != len(set(artist_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some artist IDs do not exist",
        )

    return artists


def _resolve_songs(
    db: Session,
    song_ids: List[str],
) -> List[Song]:
    if not song_ids:
        return []

    songs = (
        db.query(Song)
        .filter(Song.id.in_(song_ids))
        .all()
    )

    if len(songs) != len(set(song_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some song IDs do not exist",
        )

    return songs


# ---------- CREATE ALBUM ----------

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=AlbumOut,
)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Crea un nuovo album e collega artisti e songs tramite
    le tabelle di join AlbumArtist e AlbumSong.
    """
    album_id = str(uuid.uuid4())

    # Risolvi referenze
    artists = _resolve_artists(db, payload.artist_ids)
    songs = _resolve_songs(db, payload.song_ids)

    # Crea l'album
    db_album = Album(
        id=album_id,
        title=payload.title,
        release_date=payload.release_date,
        label=payload.label,
        album_type=payload.album_type,
        genre=genre,
        cover_url=payload.cover_url,
        total_tracks=len(songs) if songs else None,
    )

    # 🔹 CREA LE RIGHE DI JOIN (NON USARE più album.artists / album.songs: sono viewonly)
    db_album.album_artist_links = [
        AlbumArtist(
            id=str(uuid.uuid4()),
            album=db_album,
            artist=artist,
            role=None,  # se in futuro vorrai gestire 'primary', 'guest', ecc.
        )
        for artist in artists
    ]

    db_album.album_song_links = [
        AlbumSong(
            id=str(uuid.uuid4()),
            album=db_album,
            song=song,
            track_number=None,  # qui potresti gestire in futuro l'ordine delle tracce
        )
        for song in songs
    ]

    db.add(db_album)
    db.commit()

    # Ricarica con joinedload per avere artists/songs valorizzati
    db_album = _get_album_or_404(album_id, db)

    return db_album


# ---------- GET SINGOLO ALBUM ----------

@router.get(
    "/{album_id}",
    response_model=AlbumOut,
)
def get_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Restituisce un album con artisti e tracce.
    """
    album = _get_album_or_404(album_id, db)
    return album


# ---------- LISTA ALBUM ----------

@router.get(
    "/",
    response_model=List[AlbumOut],
)
def list_albums(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
    artist_id: Optional[str] = None,
):
    """
    Lista di album.

    - Se `artist_id` è valorizzato, filtra gli album di quell'artista.
    """
    query = (
        db.query(Album)
        .options(
            joinedload(Album.artists),
            joinedload(Album.songs),
        )
    )

    if artist_id:
        # usa la relazione M:N viewonly verso Artist
        query = query.join(Album.artists).filter(Artist.id == artist_id)

    albums = query.all()
    return albums


# ---------- UPDATE ALBUM ----------

@router.patch(
    "/{album_id}",
    response_model=AlbumOut,
)
def update_album(
    album_id: str,
    payload: AlbumUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Aggiornamento parziale di un album.

    - Puoi cambiare metadati (titolo, label, ecc.)
    - Puoi riassegnare lista di artisti e songs passando gli ID:
      in questo caso rimpiazziamo le righe di join album_artists / album_songs.
    """
    album = _get_album_or_404(album_id, db)

    # Metadati base
    if payload.title is not None:
        album.title = payload.title
    if payload.release_date is not None:
        album.release_date = payload.release_date
    if payload.label is not None:
        album.label = payload.label
    if payload.album_type is not None:
        album.album_type = payload.album_type
    if payload.cover_url is not None:
        album.cover_url = payload.cover_url

    # 🔹 Aggiornamento relazioni via join tables

    # 1) Artisti
    if payload.artist_ids is not None:
        artists = _resolve_artists(db, payload.artist_ids)

        # Cancella i vecchi link (delete-orphan gestito dalla relationship)
        album.album_artist_links.clear()

        # Crea nuovi link
        for artist in artists:
            album.album_artist_links.append(
                AlbumArtist(
                    id=str(uuid.uuid4()),
                    album=album,
                    artist=artist,
                    role=None,
                )
            )

    # 2) Songs
    if payload.song_ids is not None:
        songs = _resolve_songs(db, payload.song_ids)

        # Cancella i vecchi link
        album.album_song_links.clear()

        # Crea nuovi link
        for song in songs:
            album.album_song_links.append(
                AlbumSong(
                    id=str(uuid.uuid4()),
                    album=album,
                    song=song,
                    track_number=None,
                )
            )

        album.total_tracks = len(songs) if songs else None

    db.commit()

    # Ricarica con join per avere artists/songs aggiornati
    album = _get_album_or_404(album_id, db)

    return album


# ---------- DELETE ALBUM ----------

@router.delete(
    "/{album_id}",
    status_code=status.HTTP_200_OK,
)
def delete_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Cancella un album.

    Le join AlbumArtist / AlbumSong vengono eliminate grazie a
    ondelete="CASCADE" + cascade="all, delete-orphan".
    """
    album = db.query(Album).filter(Album.id == album_id).first()
    if not album:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    db.delete(album)
    db.commit()
    return {"message": "Album deleted successfully"}
