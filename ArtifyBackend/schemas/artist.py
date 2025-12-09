# pydantic_schemas/artist.py

from typing import List, Optional
from pydantic import BaseModel

from schemas.album import SongRef   # id, song_name, thumbnail_url
from schemas.song import AlbumRef   # id, title, cover_url


class ArtistBase(BaseModel):
    """
    Campi di dominio di base di un artista.
    """
    name: str
    display_name: Optional[str] = None
    slug: Optional[str] = None
    image_url: Optional[str] = None
    bio: Optional[str] = None
    country: Optional[str] = None


class ArtistCreate(ArtistBase):
    """
    Payload in input quando crei un artista.
    Puoi opzionalmente collegare già brani e album.
    """
    song_ids: List[str] = []
    album_ids: List[str] = []


class ArtistUpdate(BaseModel):
    """
    Aggiornamento parziale di un artista.
    Tutto opzionale.
    """
    name: Optional[str] = None
    display_name: Optional[str] = None
    slug: Optional[str] = None
    image_url: Optional[str] = None
    bio: Optional[str] = None
    country: Optional[str] = None

    song_ids: Optional[List[str]] = None
    album_ids: Optional[List[str]] = None


class ArtistOut(ArtistBase):
    """
    Rappresentazione pubblica di un artista verso il FE.
    """
    id: str
    songs: List[SongRef] = []
    albums: List[AlbumRef] = []

    class Config:
        orm_mode = True
