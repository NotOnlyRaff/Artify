# pydantic_schemas/user.py

from typing import List

from pydantic import BaseModel, EmailStr, Field

from schemas.album import SongRef  # ref minimale: id, song_name, thumbnail_url


class UserBase(BaseModel):
    """
    Campi di dominio comuni dell'utente
    (non include la password hashata).
    """
    name: str
    email: EmailStr


class UserCreate(UserBase):
    """
    Payload di registrazione.
    La password qui è in chiaro nel payload,
    verrà hashata nel service prima di creare l'User SQLAlchemy.
    """
    password: str


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

    # lista delle canzoni preferite (via relazione User.favorite_songs)
    favorite_songs: List[SongRef] = Field(default_factory=list)

    class Config:
        orm_mode = True
