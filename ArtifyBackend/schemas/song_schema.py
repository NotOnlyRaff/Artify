from datetime import date
from typing import List, Optional

from models.enums import SongArtistRole
from schemas.refs import AlbumRef
from pydantic import BaseModel, ConfigDict, Field, model_validator, AnyHttpUrl
from schemas.songArtist_schema import SongArtistOut

class AlbumSongLinkOut(BaseModel):
    album_id: str
    track_number: Optional[int] = Field(default=None, ge=1)
    album: Optional[AlbumRef] = None

    model_config = ConfigDict(from_attributes=True)


class SongArtistLinkIn(BaseModel):
    artist_id: str = Field(min_length=1)
    role: SongArtistRole


class SongBase(BaseModel):
    song_name: str = Field(min_length=1, max_length=100)
    song_url: AnyHttpUrl
    thumbnail_url: Optional[AnyHttpUrl] = None
    release_date: date

    composer_id: Optional[str] = None
    composer_name: Optional[str] = Field(default=None, max_length=120)

    producer_id: Optional[str] = None
    producer_name: Optional[str] = Field(default=None, max_length=120)

    genre: Optional[str] = Field(default=None, max_length=80)
    lyrics: Optional[str] = None
    mood: Optional[str] = Field(default=None, max_length=50)
    duration_seconds: Optional[int] = Field(default=None, ge=1)

    @model_validator(mode="after")
    def validate_composer(self):
        if not self.composer_id and not self.composer_name:
            raise ValueError("At least one of composer_id or composer_name must be provided")
        return self


class SongCreate(SongBase):
    artist_links: List[SongArtistLinkIn] = Field(default_factory=list)


class SongUpdate(BaseModel):
    song_name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    song_url: Optional[AnyHttpUrl] = None
    thumbnail_url: Optional[AnyHttpUrl] = None
    release_date: Optional[date] = None

    composer_id: Optional[str] = None
    composer_name: Optional[str] = Field(default=None, max_length=120)

    producer_id: Optional[str] = None
    producer_name: Optional[str] = Field(default=None, max_length=120)

    genre: Optional[str] = Field(default=None, max_length=80)
    lyrics: Optional[str] = None
    mood: Optional[str] = Field(default=None, max_length=50)
    duration_seconds: Optional[int] = Field(default=None, ge=1)

    artist_links: Optional[List[SongArtistLinkIn]] = None


class SongOut(BaseModel):
    id: str
    song_name: str
    song_url: AnyHttpUrl
    thumbnail_url: Optional[AnyHttpUrl] = None
    release_date: date

    composer_id: Optional[str] = None
    composer_name: Optional[str] = None

    producer_id: Optional[str] = None
    producer_name: Optional[str] = None

    genre: Optional[str] = None
    lyrics: Optional[str] = None
    mood: Optional[str] = None
    duration_seconds: Optional[int] = None

    artist_links: List[SongArtistOut] = Field(
        default_factory=list,
        alias="song_artist_links",
    )

    album_links: List[AlbumSongLinkOut] = Field(
        default_factory=list,
        alias="album_song_links",
    )

    model_config = ConfigDict(
        from_attributes=True,
        use_enum_values=True,
        populate_by_name=True,
    )