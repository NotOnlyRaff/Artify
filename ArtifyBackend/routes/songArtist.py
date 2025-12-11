# schemas/songArtist.py

from typing import Optional
from pydantic import BaseModel

from models.songArtist import SongArtistRole


class ArtistRef(BaseModel):
    id: str
    name: str
    image_url: Optional[str] = None

    class Config:
        orm_mode = True


class SongRef(BaseModel):
    id: str
    song_name: str
    thumbnail_url: Optional[str] = None

    class Config:
        orm_mode = True


class SongArtistBase(BaseModel):
    song_id: str
    artist_id: str
    role: SongArtistRole = SongArtistRole.PRIMARY

    class Config:
        # serializza l'enum come "primary", "featured", ecc.
        use_enum_values = True


class SongArtistCreate(SongArtistBase):
    """Payload per creare una nuova relazione song–artist con ruolo."""
    pass


class SongArtistUpdate(BaseModel):
    """Payload per aggiornare SOLO il ruolo."""
    role: SongArtistRole

    class Config:
        use_enum_values = True


class SongArtistOut(BaseModel):
    id: str
    role: SongArtistRole
    song: SongRef
    artist: ArtistRef

    class Config:
        orm_mode = True
        use_enum_values = True
