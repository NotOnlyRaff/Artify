# routes/song_artist.py

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware

from models.songArtist import SongArtist, SongArtistRole  # 👈 aggiorna il path se necessario
from models.song import Song
from models.artist import Artist

from schemas.songArtist import (
    SongArtistCreate,
    SongArtistUpdate,
    SongArtistOut,
)

router = APIRouter(tags=["song-artists"])
# nel main poi farai qualcosa tipo:
# app.include_router(router, prefix="/song-artists")


# ---------- UTILITY ----------

def _get_link_or_404(link_id: str, db: Session) -> SongArtist:
    link = (
        db.query(SongArtist)
        .options(
            joinedload(SongArtist.song),
            joinedload(SongArtist.artist),
        )
        .filter(SongArtist.id == link_id)
        .first()
    )
    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Song–Artist link not found",
        )
    return link


def _ensure_song_and_artist_exist(
    db: Session,
    song_id: str,
    artist_id: str,
) -> tuple[Song, Artist]:
    song = db.query(Song).filter(Song.id == song_id).first()
    if not song:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Song ID does not exist",
        )

    artist = db.query(Artist).filter(Artist.id == artist_id).first()
    if not artist:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Artist ID does not exist",
        )

    return song, artist


# ---------- CREATE ----------

@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=SongArtistOut,
)
def create_song_artist(
    payload: SongArtistCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Crea una nuova relazione Song–Artist con un ruolo specifico.
    Utile per gestire PRIMARY / FEATURED / PRODUCER, ecc.
    """
    song, artist = _ensure_song_and_artist_exist(
        db,
        payload.song_id,
        payload.artist_id,
    )

    link = SongArtist(
        id=str(uuid.uuid4()),
        song=song,
        artist=artist,
        role=payload.role or SongArtistRole.PRIMARY,
    )

    db.add(link)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # violazione UniqueConstraint(song_id, artist_id, role)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This song–artist–role combination already exists",
        )

    db.refresh(link)
    return link

# ---------- GET SINGOLO LINK ----------

@router.get(
    "/{link_id}",
    response_model=SongArtistOut,
)
def get_song_artist(
    link_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Restituisce una singola riga di join song–artist con ruolo.
    """
    link = _get_link_or_404(link_id, db)
    return link


# ---------- LISTA LINK ----------

@router.get(
    "/",
    response_model=List[SongArtistOut],
)
def list_song_artists(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
    song_id: Optional[str] = None,
    artist_id: Optional[str] = None,
):
    """
    Lista delle relazioni song–artist.

    Filtri opzionali:
    - `song_id`: tutte le relazioni per una certa song
    - `artist_id`: tutte le relazioni per un certo artist
    """
    query = (
        db.query(SongArtist)
        .options(
            joinedload(SongArtist.song),
            joinedload(SongArtist.artist),
        )
    )

    if song_id:
        query = query.filter(SongArtist.song_id == song_id)

    if artist_id:
        query = query.filter(SongArtist.artist_id == artist_id)

    links = query.all()
    return links


# ---------- UPDATE (RUOLO) ----------

@router.patch(
    "/{link_id}",
    response_model=SongArtistOut,
)
def update_song_artist(
    link_id: str,
    payload: SongArtistUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Aggiorna il ruolo di un link song–artist.
    Es: da FEATURED a PRIMARY, ecc.
    """
    link = _get_link_or_404(link_id, db)

    if payload.role is not None:
        link.role = payload.role

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # se cambi ruolo causando un duplicato (stessa song, artist, role)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A link with this song, artist and role already exists",
        )

    db.refresh(link)
    return link


# ---------- DELETE ----------

@router.delete(
    "/{link_id}",
    status_code=status.HTTP_200_OK,
)
def delete_song_artist(
    link_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Cancella una relazione song–artist.
    Non cancella né la song né l'artist.
    """
    link = db.query(SongArtist).filter(SongArtist.id == link_id).first()
    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Song–Artist link not found",
        )

    db.delete(link)
    db.commit()
    return {"message": "Song–Artist link deleted successfully"}