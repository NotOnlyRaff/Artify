from sqlalchemy import TEXT, VARCHAR, Column, Date, Integer
from sqlalchemy import ForeignKey
from models.base import Base

class AlbumSong(Base):
    __tablename__ = "album_songs"
    album_id = Column(TEXT, ForeignKey("albums.id"), primary_key=True)
    song_id  = Column(TEXT, ForeignKey("songs.id"), primary_key=True)
    track_number = Column(Integer, nullable=True)