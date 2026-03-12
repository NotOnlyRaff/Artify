import enum

from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary, Enum as SAEnum
from sqlalchemy.orm import relationship
from models.base import Base

class UserRole(str, enum.Enum):
    ADMIN = "admin"
    ARTIST = "artist"
    USER = "user"

class User(Base):
    __tablename__ = "users"

    id = Column(TEXT, primary_key=True)
    name = Column(VARCHAR(100), nullable=False)
    email = Column(VARCHAR(100), nullable=False, unique=True, index=True)
    password = Column(LargeBinary, nullable=False)

    role = Column(SAEnum(UserRole), default=UserRole.USER, nullable=False)
    artist_profile = relationship("Artist", back_populates="user", uselist=False)
    
    @property
    def artist_id(self):
        # Se l'utente ha un profilo artista, restituisci il suo ID, altrimenti None
        return self.artist_profile.id if self.artist_profile else None
    
    favorites = relationship(
        "Favorite",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    favorite_songs = relationship(
        "Song",
        secondary="favorites",
        viewonly=True,
        overlaps="favorites,song,user",
    )
