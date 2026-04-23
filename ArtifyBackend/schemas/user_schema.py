from typing import List, Optional

from models.enums import UserRole
from schemas.refs import SongRef
from pydantic import BaseModel, ConfigDict, EmailStr, Field, AnyHttpUrl

class UserBase(BaseModel):
    """
    Campi comuni dell'utente esposti/accettati a livello schema.
    Non include mai la password hashata.
    """
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    image_url: Optional[AnyHttpUrl] = None


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)
    is_artist: bool = False


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserUpdate(BaseModel):
    """
    Schema per aggiornare il profilo utente.
    """
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    image_url: Optional[AnyHttpUrl] = None


class UserPasswordChange(BaseModel):
    current_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)

class AdminPasswordReset(BaseModel):
    new_password: str = Field(min_length=8, max_length=128)


class UserOut(UserBase):
    """
    Rappresentazione pubblica dell'utente verso il frontend.
    Non espone mai la password.
    """
    id: str
    role: UserRole
    artist_id: Optional[str] = None
    favorite_songs: List[SongRef] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)