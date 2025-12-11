from sqlalchemy import TEXT, Column, ForeignKey
from sqlalchemy.orm import relationship
from models.base import Base


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(TEXT, primary_key=True)
    song_id = Column(TEXT, ForeignKey("songs.id", ondelete="CASCADE"))
    user_id = Column(TEXT, ForeignKey("users.id", ondelete="CASCADE"))

    song = relationship("Song", back_populates="favorites")
    user = relationship("User", back_populates="favorites")
