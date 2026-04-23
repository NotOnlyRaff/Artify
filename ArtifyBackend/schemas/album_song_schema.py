from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from schemas.refs import AlbumRef, SongRef

class AlbumSongBase(BaseModel):
    """
    Base comune per la relazione album-song.
    """
    album_id: str = Field(min_length=1)
    song_id: str = Field(min_length=1)
    track_number: Optional[int] = Field(default=None, ge=1)


class AlbumSongCreate(AlbumSongBase):
    """
    Payload per collegare una song a un album.
    """
    pass


class AlbumSongUpdate(BaseModel):
    """
    Aggiorna solo la posizione del brano nell'album.
    """
    track_number: Optional[int] = Field(default=None, ge=1)


class AlbumSongOut(BaseModel):
    """
    Output completo della relazione album-song.
    """
    id: str
    album_id: str
    song_id: str
    track_number: Optional[int] = Field(default=None, ge=1)

    album: AlbumRef
    song: SongRef

    model_config = ConfigDict(from_attributes=True)