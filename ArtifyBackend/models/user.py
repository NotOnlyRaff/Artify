from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary
from sqlalchemy.orm import relationship
from models.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(TEXT, primary_key=True)
    name = Column(VARCHAR(100), nullable=False)
    email = Column(VARCHAR(100), nullable=False, unique=True, index=True)
    password = Column(LargeBinary, nullable=False)

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
