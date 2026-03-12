# pydantic_schemas/song_artist.py

from typing import Optional

from pydantic import BaseModel, ConfigDict

# ATTENZIONE: usa il path reale del tuo file model
# se il file è models/song_artist.py:
from models.songArtist import SongArtistRole
# se invece il file si chiama ancora models/songArtist.py, lascia:
# from models.songArtist import SongArtistRole


# ---------- REF MINIMALI (solo per SongArtistOut) ----------

class ArtistRef(BaseModel):
    """
    Rappresentazione leggera di Artist usata dentro SongArtistOut.
    Manteniamo la stessa shape usata negli altri schemi.
    """
    id: str
    name: str
    display_name: Optional[str] = None
    image_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SongRef(BaseModel):
    """
    Rappresentazione leggera di Song usata dentro SongArtistOut.
    Stessa shape di SongRef in album/artist.
    """
    id: str
    song_name: str
    thumbnail_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# ---------- BASE / CREATE / UPDATE ----------

class SongArtistBase(BaseModel):
    song_id: str
    artist_id: str
    role: SongArtistRole = SongArtistRole.PRIMARY

    model_config = ConfigDict(use_enum_values=True)


class SongArtistCreate(SongArtistBase):
    """
    Payload per creare una nuova relazione song–artist con ruolo.
    """
    pass


class SongArtistUpdate(BaseModel):
    """
    Payload per aggiornare SOLO il ruolo.
    """
    role: SongArtistRole

    model_config = ConfigDict(use_enum_values=True)


# ---------- OUTPUT ----------

class SongArtistOut(BaseModel):
    """
    Come serializziamo la join Song–Artist con ruolo verso il FE.
    """
    id: str
    role: SongArtistRole
    song: SongRef
    artist: ArtistRef

    model_config = ConfigDict(
        from_attributes=True, 
        use_enum_values=True
    )
