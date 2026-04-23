from datetime import date
from typing import List, Optional
from models.enums import AlbumArtistRole
from pydantic import BaseModel, ConfigDict, Field, model_validator, AnyHttpUrl
from schemas.refs import ArtistRef, SongRef


class AlbumBase(BaseModel):
    """
    Campi di dominio di base dell'album.
    """
    title: str = Field(min_length=1, max_length=200)
    release_date: Optional[date] = None
    label: Optional[str] = Field(default=None, max_length=120)
    album_type: Optional[str] = Field(default=None, max_length=30)
    genre: Optional[str] = Field(default=None, max_length=30)


class AlbumSongAttachIn(BaseModel):
    """
    Collega una song già esistente a un album.
    """
    song_id: str = Field(min_length=1)
    track_number: int = Field(ge=1)


class AlbumCreate(AlbumBase):
    """
    Crea l'album.
    Può opzionalmente:
    - collegare artisti già esistenti
    - collegare song già esistenti con track_number
    NON crea nuove song.
    """
    cover_url: Optional[AnyHttpUrl] = None
    artist_ids: List[str] = Field(default_factory=list)
    song_links: List[AlbumSongAttachIn] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_song_links(self):
        song_ids = [link.song_id for link in self.song_links]
        if len(song_ids) != len(set(song_ids)):
            raise ValueError("Duplicate song_id values are not allowed in song_links")

        track_numbers = [link.track_number for link in self.song_links]
        if len(track_numbers) != len(set(track_numbers)):
            raise ValueError("Duplicate track_number values are not allowed in song_links")

        return self


class AlbumUpdate(BaseModel):
    """
    Aggiornamento parziale dei metadati album.
    Le song si gestiscono con endpoint dedicati.
    """
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    release_date: Optional[date] = None
    label: Optional[str] = Field(default=None, max_length=120)
    album_type: Optional[str] = Field(default=None, max_length=30)
    cover_url: Optional[AnyHttpUrl] = None
    genre: Optional[str] = Field(default=None, max_length=30)

    artist_ids: Optional[List[str]] = None


class AlbumAddSongs(BaseModel):
    """
    Aggiunge song già esistenti a un album esistente.
    """
    song_links: List[AlbumSongAttachIn] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_song_links(self):
        song_ids = [link.song_id for link in self.song_links]
        if len(song_ids) != len(set(song_ids)):
            raise ValueError("Duplicate song_id values are not allowed in song_links")

        track_numbers = [link.track_number for link in self.song_links]
        if len(track_numbers) != len(set(track_numbers)):
            raise ValueError("Duplicate track_number values are not allowed in song_links")

        return self


class AlbumArtistLinkOut(BaseModel):
    artist_id: str
    role: Optional[AlbumArtistRole] = None
    artist: Optional[ArtistRef] = None

    model_config = ConfigDict(from_attributes=True)




class AlbumSongLinkOut(BaseModel):
    song_id: str
    track_number: Optional[int] = Field(default=None, ge=1)
    song: Optional[SongRef] = None

    model_config = ConfigDict(from_attributes=True)


class AlbumOut(AlbumBase):
    """
    Output coerente con il model ORM attuale.
    """
    id: str
    cover_url: Optional[AnyHttpUrl] = None

    album_artist_links: List[AlbumArtistLinkOut] = Field(default_factory=list)
    album_song_links: List[AlbumSongLinkOut] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)