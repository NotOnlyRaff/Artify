# schemas/song.py

from datetime import date
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field
from models.songArtist import SongArtistRole
from schemas.songArtist_schema import SongArtistOut


# --- REF MINIMALI USATI DA ALBUM E SONG ---


class ArtistRef(BaseModel):
    """
    Versione leggera di Artist usata dentro Song e Album.
    """
    id: str
    name: str
    display_name: Optional[str] = None
    image_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class AlbumRef(BaseModel):
    """
    Versione leggera di Album usata dentro Song.
    """
    id: str
    title: str
    cover_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# --- BASE / CREATE / UPDATE ---


class SongBase(BaseModel):
    song_name: str
    song_url: str                    # ✅ type annotation corretta
    thumbnail_url: Optional[str] = None
    release_date: Optional[date] = None
    composer_name: str
    producer_name: Optional[str] = None
    genre: Optional[str] = None
    lyrics: Optional[str] = None
    mood: Optional[str] = None
    duration_seconds: Optional[int] = None


class SongCreate(SongBase):
    # meglio evitare liste/dict mutabili come default: usa default_factory
    artist_ids: List[str] = Field(default_factory=list)
    artist_roles: Dict[str, SongArtistRole] = Field(default_factory=dict)


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

    artist_links: List[SongArtistOut] = Field(
        default_factory=list,
        alias="song_artist_links",
    )
    artists: List[ArtistRef] = Field(default_factory=list)
    albums: List[AlbumRef] = Field(default_factory=list)

    model_config = ConfigDict(  
        from_attributes=True, 
        use_enum_values=True,
        populate_by_name=True # Permette di usare sia l'alias che il nome del campo
    )
