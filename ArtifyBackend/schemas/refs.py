from typing import Optional

from pydantic import BaseModel, ConfigDict


class ArtistRef(BaseModel):
    id: str
    name: str
    display_name: Optional[str] = None
    image_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SongRef(BaseModel):
    id: str
    song_name: str
    thumbnail_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class AlbumRef(BaseModel):
    id: str
    title: str
    cover_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class UserRef(BaseModel):
    id: str
    name: str
    image_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)