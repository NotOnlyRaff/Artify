# pydantic_schemas/album_artist.py

from typing import Optional

from pydantic import BaseModel, ConfigDict

from schemas.song_schema import ArtistRef, AlbumRef
# ArtistRef: id, name, display_name, image_url
# AlbumRef:  id, title, cover_url


class AlbumArtistBase(BaseModel):
    """
    Base comune per la relazione album–artist.
    Per ora role rimane una semplice stringa, come nel model SQLAlchemy.
    """
    album_id: str
    artist_id: str
    role: Optional[str] = None  # 'primary', 'guest', ecc.


class AlbumArtistCreate(AlbumArtistBase):
    """
    Payload per creare un nuovo collegamento album–artist.
    """
    pass


class AlbumArtistUpdate(BaseModel):
    """
    Aggiorna solo il ruolo dell'artista su un album.
    """
    role: Optional[str] = None


class AlbumArtistOut(BaseModel):
    """
    Output completo di una riga album_artists.
    Utile se vuoi endpoint /admin o debug.
    """
    id: str
    role: Optional[str] = None

    album: AlbumRef
    artist: ArtistRef

    model_config = ConfigDict(from_attributes=True)
