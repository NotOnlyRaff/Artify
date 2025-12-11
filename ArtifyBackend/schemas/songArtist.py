# pydantic_schemas/song_artist.py

from typing import Optional, List
from pydantic import BaseModel

from models.songArtist import SongArtistRole


# ---------- REF MINIMALI (se li hai già altrove, riusali) ----------

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


# ---------- BASE / CREATE / UPDATE ----------

class SongArtistBase(BaseModel):
    song_id: str
    artist_id: str
    role: SongArtistRole = SongArtistRole.PRIMARY  # Enum usato anche nel model

    class Config:
        use_enum_values = True   # quando serializzi, manda "primary", "featured", ecc.


class SongArtistCreate(SongArtistBase):
    """Payload per creare una nuova relazione song–artist con ruolo."""
    pass


class SongArtistUpdate(BaseModel):
    """Payload per aggiornare SOLO il ruolo."""
    role: SongArtistRole

    class Config:
        use_enum_values = True


# ---------- OUTPUT ----------

class SongArtistOut(BaseModel):
    id: str
    role: SongArtistRole
    song: SongRef
    artist: ArtistRef

    class Config:
        orm_mode = True          # legge direttamente da oggetto ORM
        use_enum_values = True
