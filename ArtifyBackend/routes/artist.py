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
from schemas.artist import ArtistCreate, ArtistUpdate, ArtistOut

router = APIRouter(tags=["artists"])


# ---------- UTILITY INTERNE ----------

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
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=ArtistOut,
)
def create_artist(
    payload: ArtistCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Crea un nuovo artista e (opzionalmente) collega canzoni e album.
    """
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

    db_artist.songs = songs
    db_artist.albums = albums

    db.add(db_artist)
    db.commit()
    db.refresh(db_artist)

    return db_artist


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
    """
    Restituisce un artista con le sue canzoni e i suoi album.
    """
    artist = _get_artist_or_404(artist_id, db)
    return artist


# ---------- LISTA ARTISTI ----------

@router.get(
    "/",
    response_model=List[ArtistOut],
)
def list_artists(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
    search: Optional[str] = None,
    song_id: Optional[str] = None,
    album_id: Optional[str] = None,
):
    """
    Lista di artisti.

    Filtri opzionali:
    - `search`: match su name / display_name
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

    if search:
        pattern = f"%{search.lower()}%"
        # dipende dal DB engine, su Postgres potresti usare il lower in modo più pulito
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
    """
    Aggiornamento parziale di un artista:
    - metadati (name, image_url, bio, country, ...)
    - relazioni (song_ids, album_ids)
    """
    artist = _get_artist_or_404(artist_id, db)

    # Metadati base
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

    # Relazioni
    if payload.song_ids is not None:
        songs = _resolve_songs(db, payload.song_ids)
        artist.songs = songs

    if payload.album_ids is not None:
        albums = _resolve_albums(db, payload.album_ids)
        artist.albums = albums

    db.commit()
    db.refresh(artist)

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
    """
    Cancella un artista.
    Le join table si occupano di staccare le relazioni M:N.
    """
    artist = db.query(Artist).filter(Artist.id == artist_id).first()
    if not artist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artist not found",
        )

    db.delete(artist)
    db.commit()
    return {"message": "Artist deleted successfully"}
