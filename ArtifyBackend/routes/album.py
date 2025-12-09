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
from schemas.album import AlbumCreate, AlbumUpdate, AlbumOut

router = APIRouter(tags=["albums"])


# ---------- UTILITY INTERNA ----------

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
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=AlbumOut,
)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Crea un nuovo album e collega artisti e songs.
    """
    album_id = str(uuid.uuid4())

    # Risolvi referenze
    artists = _resolve_artists(db, payload.artist_ids)
    songs = _resolve_songs(db, payload.song_ids)

    db_album = Album(
        id=album_id,
        title=payload.title,
        release_date=payload.release_date,
        label=payload.label,
        album_type=payload.album_type,
        cover_url=payload.cover_url,
        total_tracks=len(songs) if songs else None,
    )

    db_album.artists = artists
    db_album.songs = songs

    db.add(db_album)
    db.commit()
    db.refresh(db_album)

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
    - Puoi riassegnare lista di artisti e songs passando gli ID.
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

    # Aggiornamento relazioni
    if payload.artist_ids is not None:
        artists = _resolve_artists(db, payload.artist_ids)
        album.artists = artists

    if payload.song_ids is not None:
        songs = _resolve_songs(db, payload.song_ids)
        album.songs = songs
        album.total_tracks = len(songs) if songs else None

    db.commit()
    db.refresh(album)

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

    Le relazioni M:N con artists e songs vengono gestite tramite la join table.
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
