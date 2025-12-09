# routes/song_artist.py

import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware
from models.song import Song
from models.artist import Artist
from models.songArtist import SongArtist
from schemas.songArtist import (
    SongArtistCreate,
    SongArtistUpdate,
    SongArtistOut,
)

router = APIRouter(
    prefix="/song-artist",
    tags=["song-artist"],
)


# CREATE: collega song ⟷ artist con un ruolo
@router.post(
    "/",
    response_model=SongArtistOut,
    status_code=status.HTTP_201_CREATED,
)
def create_song_artist_link(
    payload: SongArtistCreate,
    db: Session = Depends(get_db),
    auth=Depends(auth_middleware),
):
    # Check esistenza song
    song = db.query(Song).filter(Song.id == payload.song_id).first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")

    # Check esistenza artist
    artist = db.query(Artist).filter(Artist.id == payload.artist_id).first()
    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found")

    # Evita duplicati (stessa song, stesso artist)
    existing = (
        db.query(SongArtist)
        .filter(
            SongArtist.song_id == payload.song_id,
            SongArtist.artist_id == payload.artist_id,
        )
        .first()
    )
    if existing:
        # volendo qui potresti aggiornare il ruolo invece di dare errore
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Relation song-artist already exists",
        )

    link = SongArtist(
        id=str(uuid.uuid4()),
        song_id=payload.song_id,
        artist_id=payload.artist_id,
        role=payload.role,
    )

    db.add(link)
    db.commit()
    db.refresh(link)
    return link


# LIST: tutti gli artist con ruolo per una song
@router.get(
    "/by-song/{song_id}",
    response_model=List[SongArtistOut],
)
def list_artists_for_song(
    song_id: str,
    db: Session = Depends(get_db),
    auth=Depends(auth_middleware),
):
    links = (
        db.query(SongArtist)
        .options(
            joinedload(SongArtist.artist),
            joinedload(SongArtist.song),
        )
        .filter(SongArtist.song_id == song_id)
        .all()
    )
    return links


# LIST: tutte le song con ruolo per un artist
@router.get(
    "/by-artist/{artist_id}",
    response_model=List[SongArtistOut],
)
def list_songs_for_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    auth=Depends(auth_middleware),
):
    links = (
        db.query(SongArtist)
        .options(
            joinedload(SongArtist.song),
            joinedload(SongArtist.artist),
        )
        .filter(SongArtist.artist_id == artist_id)
        .all()
    )
    return links


# UPDATE: cambia solo il ruolo
@router.patch(
    "/{link_id}",
    response_model=SongArtistOut,
)
def update_song_artist_role(
    link_id: str,
    payload: SongArtistUpdate,
    db: Session = Depends(get_db),
    auth=Depends(auth_middleware),
):
    link = db.query(SongArtist).filter(SongArtist.id == link_id).first()
    if not link:
        raise HTTPException(status_code=404, detail="Relation not found")

    link.role = payload.role
    db.commit()
    db.refresh(link)
    return link


# DELETE: elimina una relazione song–artist
@router.delete(
    "/{link_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_song_artist_link(
    link_id: str,
    db: Session = Depends(get_db),
    auth=Depends(auth_middleware),
):
    link = db.query(SongArtist).filter(SongArtist.id == link_id).first()
    if not link:
        raise HTTPException(status_code=404, detail="Relation not found")

    db.delete(link)
    db.commit()
    return None
