from ArtifyBackend.models.enums import AlbumArtistRole
from pydantic import BaseModel, ConfigDict, Field
from schemas.refs import AlbumRef, ArtistRef



class AlbumArtistBase(BaseModel):
    """
    Base comune per la relazione album-artist.
    """
    album_id: str = Field(min_length=1)
    artist_id: str = Field(min_length=1)
    role: AlbumArtistRole = AlbumArtistRole.PRIMARY

    model_config = ConfigDict(use_enum_values=True)


class AlbumArtistCreate(AlbumArtistBase):
    """
    Payload per creare un nuovo collegamento album-artist.
    """
    pass


class AlbumArtistUpdate(BaseModel):
    """
    Aggiorna solo il ruolo dell'artista su un album.
    """
    role: AlbumArtistRole

    model_config = ConfigDict(use_enum_values=True)


class AlbumArtistOut(BaseModel):
    """
    Output completo di una riga album_artists.
    """
    id: str
    album_id: str
    artist_id: str
    role: AlbumArtistRole

    album: AlbumRef
    artist: ArtistRef

    model_config = ConfigDict(
        from_attributes=True,
        use_enum_values=True,
    )