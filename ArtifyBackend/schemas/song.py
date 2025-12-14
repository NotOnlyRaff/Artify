# schemas/song.py

from datetime import date
from typing import List, Optional

from pydantic import BaseModel, Field

from schemas.songArtist import SongArtistOut  # se il path è diverso, adattalo


# --- REF MINIMALI USATI DA ALBUM E SONG ---


class ArtistRef(BaseModel):
    """
    Versione leggera di Artist usata dentro Song e Album.
    """
    id: str
    name: str
    display_name: Optional[str] = None
    image_url: Optional[str] = None

    class Config:
        orm_mode = True


class AlbumRef(BaseModel):
    """
    Versione leggera di Album usata dentro Song.
    """
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
    """
    Payload di input per creare un brano.
    artist_ids e album_ids servono a popolare le tabelle di join.
    Se gestisci song_url a livello di servizio (es. dopo upload su S3),
    puoi continuare a non richiederlo nel payload.
    """
    artist_ids: List[str] = Field(default_factory=list)
    album_ids: List[str] = Field(default_factory=list)


class SongUpdate(BaseModel):
    """
    Payload di aggiornamento parziale.
    Tutto opzionale.
    """
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
    """
    Come viene serializzato un brano verso il frontend.
    """
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

    # join esplicite song <-> artist (con ruolo, ecc.)
    # NB: il nome del campo ora combacia con la relationship SQLAlchemy:
    # Song.song_artist_links
    artist_links: List[SongArtistOut] = Field(
        default_factory=list,
        alias="song_artist_links",  # nome della relationship in SQLAlchemy
    )

    # lista di artisti (M:N "di comodo", via Song.artists)
    artists: List[ArtistRef] = Field(default_factory=list)

    # lista di album (M:N "di comodo", via Song.albums)
    albums: List[AlbumRef] = Field(default_factory=list)

    class Config:
        orm_mode = True
