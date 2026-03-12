# pydantic_schemas/favorite.py

from typing import Optional

from pydantic import BaseModel, ConfigDict

from schemas.album_schema import SongRef  # id, song_name, thumbnail_url


class FavoriteBase(BaseModel):
    """
    Base comune: identifica la canzone da mettere/togliere dai preferiti.
    Di solito l'utente viene preso dal token, quindi user_id non serve in input.
    """
    song_id: str


class FavoriteCreate(FavoriteBase):
    """
    Payload usato per aggiungere un brano ai preferiti dell'utente corrente.
    """
    pass


class FavoriteOut(BaseModel):
    """
    Rappresentazione di una riga della tabella favorites.
    Puoi esporre user_id o meno a seconda delle tue esigenze API.
    """
    id: str
    user_id: str
    song_id: str

    # opzionale: includi anche i dati della canzone agganciata
    song: Optional[SongRef] = None

    model_config = ConfigDict(from_attributes=True)
