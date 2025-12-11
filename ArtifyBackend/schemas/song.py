# schemas/song.py
from datetime import date
from typing import List, Optional

from pydantic import BaseModel

from schemas.songArtist import SongArtistOut  # 👈 importa l'output del link
# se il modulo ha nome diverso (es. pydantic_schemas.song_artist), adatta l'import

# --- REF MINIMALE PER ALBUM ---

class AlbumRef(BaseModel):
    id: str
    title: str
    cover_url: Optional[str] = None

    class Config:
        orm_mode = True


# --- BASE / CREATE / UPDATE ---

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


# --- OUTPUT PRINCIPALE USATO DALLE API ---

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

    # 👇 elenco dei link song–artist, con ruolo e artista annesso
    artist_links: List[SongArtistOut] = []

    # elenco degli album a cui il brano appartiene (minimal ref)
    albums: List[AlbumRef] = []

    class Config:
        orm_mode = True
