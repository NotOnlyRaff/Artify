from typing import List, Optional

from models.enums import AlbumArtistRole, SongArtistRole
from schemas.refs import AlbumRef, SongRef, UserRef
from pydantic import BaseModel, ConfigDict, Field, AnyHttpUrl


class ArtistSongLinkOut(BaseModel):
    id: str
    song_id: str
    role: SongArtistRole
    song: Optional[SongRef] = None

    model_config = ConfigDict(
        from_attributes=True,
        use_enum_values=True,
    )


class ArtistAlbumLinkOut(BaseModel):
    id: str
    album_id: str
    role: Optional[AlbumArtistRole] = None
    album: Optional[AlbumRef] = None

    model_config = ConfigDict(from_attributes=True, use_enum_values=True)


class ArtistBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    display_name: Optional[str] = Field(default=None, max_length=120)
    slug: Optional[str] = Field(default=None, max_length=140)
    image_url: Optional[AnyHttpUrl] = None
    bio: Optional[str] = None
    country: Optional[str] = Field(default=None, max_length=80)


class ArtistCreate(ArtistBase):
    pass


class ArtistUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    display_name: Optional[str] = Field(default=None, max_length=120)
    slug: Optional[str] = Field(default=None, max_length=140)
    image_url: Optional[AnyHttpUrl] = None
    bio: Optional[str] = None
    country: Optional[str] = Field(default=None, max_length=80)


class ArtistOut(ArtistBase):
    id: str
    user: Optional[UserRef] = None

    song_artist_links: List[ArtistSongLinkOut] = Field(default_factory=list)
    album_artist_links: List[ArtistAlbumLinkOut] = Field(default_factory=list)

    model_config = ConfigDict(
        from_attributes=True,
        use_enum_values=True,
    )