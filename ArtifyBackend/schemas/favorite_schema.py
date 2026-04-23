from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from schemas.refs import SongRef


class FavoriteBase(BaseModel):
    """
    Base comune: identifica la canzone da aggiungere/rimuovere dai preferiti.
    L'utente viene dedotto dal token/autenticazione.
    """
    song_id: str = Field(min_length=1)


class FavoriteCreate(FavoriteBase):
    """
    Payload per aggiungere un brano ai preferiti dell'utente corrente.
    """
    pass


class FavoriteOut(BaseModel):
    """
    Rappresentazione di una riga della tabella favorites.
    """
    id: str
    user_id: str
    song_id: str
    created_at: datetime

    song: Optional[SongRef] = None

    model_config = ConfigDict(from_attributes=True)