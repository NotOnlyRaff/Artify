# pydantic_schemas/album.py

from datetime import date
from typing import List, Optional

from pydantic import BaseModel

# Riutilizziamo il ref dell'artista già definito negli schemi di Song
from schemas.song import ArtistRef


class SongRef(BaseModel):
    """
    Versione "leggera" di Song usata dentro un Album.
    Non serve tutto SongOut, bastano pochi campi.
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


class AlbumCreate(AlbumBase):
    """
    Payload di input quando crei un album.
    Il FE ti manda gli id di artisti e song da collegare.
    """
    cover_url: Optional[str] = None
    artist_ids: List[str] = []
    song_ids: List[str] = []


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

    artist_ids: Optional[List[str]] = None
    song_ids: Optional[List[str]] = None


class AlbumOut(AlbumBase):
    """
    Come l'album viene visto dal frontend.
    """
    id: str
    cover_url: Optional[str] = None
    total_tracks: Optional[int] = None

    artists: List[ArtistRef] = []
    songs: List[SongRef] = []

    class Config:
        orm_mode = True
