# schemas/song.py
from datetime import date
from typing import List, Optional

from pydantic import BaseModel


class ArtistRef(BaseModel):
    id: str
    name: str

    class Config:
        orm_mode = True


class AlbumRef(BaseModel):
    id: str
    title: str
    cover_url: Optional[str] = None

    class Config:
        orm_mode = True

class SongBase(BaseModel):
    song_name: str
    release_date: date
    composer_name: str
    producer_name: Optional[str] = None
    genre: Optional[str] = None
    lyrics: Optional[str] = None
    mood: Optional[str] = None
    duration_seconds: Optional[int] = None


class SongCreate(SongBase):
    # Associazioni logiche: chi ha fatto il brano e a quali album appartiene
    artist_ids: List[str] = []
    album_ids: List[str] = []

class SongUpdate(BaseModel):
    song_name: Optional[str] = None
    release_date: Optional[date] = None
    composer_name: Optional[str] = None
    producer_name: Optional[str] = None
    genre: Optional[str] = None
    lyrics: Optional[str] = None
    mood: Optional[str] = None
    duration_seconds: Optional[int] = None

    artist_ids: Optional[List[str]] = None
    album_ids: Optional[List[str]] = None


class SongOut(BaseModel):
    id: str

    song_name: str
    song_url: str
    thumbnail_url: Optional[str] = None

    release_date: date
    composer_name: str
    producer_name: Optional[str] = None
    genre: Optional[str] = None
    lyrics: Optional[str] = None
    mood: Optional[str] = None
    duration_seconds: Optional[int] = None

    artists: List[ArtistRef] = []
    albums: List[AlbumRef] = []

    class Config:
        orm_mode = True
