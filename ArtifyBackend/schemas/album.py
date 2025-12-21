# schemas/album.py

from datetime import date
from typing import List, Optional

from pydantic import BaseModel, Field
from models.song import Song
from schemas.song import ArtistRef, SongCreate   # id, name, display_name, image_url


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

    - artist_ids: artisti dell'album
    - song_ids:  songs già esistenti nel DB, collegate in ordine
    - new_songs: nuove songs da creare e collegare
    """
    cover_url: Optional[str] = None
    artist_ids: List[str] = Field(default_factory=list)
    song_ids: List[str] = Field(default_factory=list)
    new_songs: List[SongCreate] = Field(default_factory=list)


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
