# pydantic_schemas/user.py

from typing import List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from models.user import UserRole
from schemas.album_schema import SongRef  # ref minimale: id, song_name, thumbnail_url


class UserBase(BaseModel):
    """
    Campi di dominio comuni dell'utente
    (non include la password hashata).
    """
    name: str
    email: EmailStr
    image_url: Optional[str] = None


class UserCreate(UserBase):
    """
    Payload di registrazione.
    La password qui è in chiaro nel payload,
    verrà hashata nel service prima di creare l'User SQLAlchemy.
    """
    password: str
    is_artist: bool = False


class UserLogin(BaseModel):
    """
    Payload per login.
    """
    email: EmailStr
    password: str


class UserOut(UserBase):
    """
    Rappresentazione pubblica dell'utente verso il frontend.
    Non espone mai la password.
    """
    id: str
    role: UserRole

    artist_id: Optional[str] = None
    
    # lista delle canzoni preferite (via relazione User.favorite_songs)
    favorite_songs: List[SongRef] = Field(default_factory=list)


    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    """
    Schema per aggiornare il profilo (es. cambiare nome o foto)
    """
    name: Optional[str] = None
    image_url: Optional[str] = None

class UserPasswordChange(BaseModel):
    current_password: Optional[str] = None
    new_password: str = Field(min_length=8, max_length=128)