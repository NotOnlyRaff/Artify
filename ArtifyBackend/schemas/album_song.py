# pydantic_schemas/album_song.py

from typing import Optional

from pydantic import BaseModel

from schemas.album import SongRef   # id, song_name, thumbnail_url
from schemas.song import AlbumRef   # id, title, cover_url


class AlbumSongBase(BaseModel):
    """
    Base comune per la relazione album–song.
    """
    album_id: str
    song_id: str
    track_number: Optional[int] = None


class AlbumSongCreate(AlbumSongBase):
    """
    Payload per aggiungere una song a un album (con track_number opzionale).
    """
    pass


class AlbumSongUpdate(BaseModel):
    """
    Aggiorna solo la posizione del brano nell'album.
    """
    track_number: Optional[int] = None


class AlbumSongOut(BaseModel):
    """
    Output completo di una riga album_songs.
    Utile per vedere/gestire la tracklist di un album.
    """
    id: str
    track_number: Optional[int] = None

    album: AlbumRef
    song: SongRef

    class Config:
        orm_mode = True
