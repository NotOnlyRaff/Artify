from typing import Optional

from models.enums import SongArtistRole
from schemas.refs import ArtistRef, SongRef
from pydantic import BaseModel, ConfigDict, Field


class SongArtistBase(BaseModel):
    song_id: str = Field(min_length=1)
    artist_id: str = Field(min_length=1)
    role: SongArtistRole = SongArtistRole.PRIMARY

    model_config = ConfigDict(use_enum_values=True)


class SongArtistCreate(SongArtistBase):
    pass


class SongArtistUpdate(BaseModel):
    role: SongArtistRole

    model_config = ConfigDict(use_enum_values=True)


class SongArtistOut(BaseModel):
    id: str
    role: SongArtistRole
    song: SongRef
    artist: ArtistRef

    model_config = ConfigDict(
        from_attributes=True,
        use_enum_values=True,
    )