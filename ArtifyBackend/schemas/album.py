# pydantic_schemas/album.py

from datetime import date
from typing import List, Optional

from pydantic import BaseModel, Field

# ATTENZIONE: aggiorna l'import al path reale del tuo progetto
# prima era: from schemas.song import ArtistRef
from schemas.song import ArtistRef


class SongRef(BaseModel):
    """
    Versione leggera di Song usata dentro un Album.
    """
    id: str
    song_name: str
    thumbnail_url: Optional[str] = None

    class Config:
        orm_mode = True


class AlbumBase(BaseModel):
    """
    Campi di dominio di base dell'album (senza id, senza relazioni).
    """
    title: str
    release_date: Optional[date] = None
    label: Optional[str] = None
    album_type: Optional[str] = None  # "album", "single", "ep", ...
    genre: Optional[str] = None


class AlbumCreate(AlbumBase):
    """
    Payload di input quando crei un album.
    Il FE ti manda gli id di artisti e song da collegare.
    """
    cover_url: Optional[str] = None
    # usare Field(default_factory=list) evita problemi di default mutabile
    artist_ids: List[str] = Field(default_factory=list)
    song_ids: List[str] = Field(default_factory=list)


class AlbumUpdate(BaseModel):
    """
    Payload per aggiornamento parziale (PATCH/PUT).
    Tutto opzionale.
    """
    title: Optional[str] = None
    release_date: Optional[date] = None
    label: Optional[str] = None
    album_type: Optional[str] = None
    cover_url: Optional[str] = None
    genre: Optional[str] = None

    artist_ids: Optional[List[str]] = None
    song_ids: Optional[List[str]] = None


class AlbumOut(AlbumBase):
    """
    Come l'album viene visto dal frontend.
    """
    id: str
    cover_url: Optional[str] = None
    total_tracks: Optional[int] = None

    artists: List[ArtistRef] = Field(default_factory=list)
    songs: List[SongRef] = Field(default_factory=list)

    class Config:
        orm_mode = True
