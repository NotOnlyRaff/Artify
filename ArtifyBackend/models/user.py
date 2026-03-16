from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary, Enum as SAEnum, ForeignKey # Aggiungi ForeignKey
from sqlalchemy.orm import relationship
from models.base import Base
import enum

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
    image_url = Column(TEXT, nullable=True)

    # 1:1 reale lato DB:
    # - nullable=True perché un utente normale può non avere un profilo artista
    # - unique=True perché un artista non può essere condiviso da più utenti
    # - ondelete="SET NULL" per evitare riferimenti rotti se l'artist viene eliminato
    artist_id = Column(
        TEXT,
        ForeignKey("artists.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
        index=True,
    )

    # 2. AGGIORNA LA RELAZIONE
    # Se il modello Artist ha user_id, usa quello. 
    # Ma se vuoi collegarli tramite l'artist_id nello User:
    artist_profile = relationship("Artist", back_populates="user", uselist=False, foreign_keys=[artist_id])
    
    # Rimuovi la vecchia @property artist_id perché ora è una colonna vera
    
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