from sqlalchemy import TEXT, Column, ForeignKey, Integer
from sqlalchemy.orm import relationship
from models.base import Base


class AlbumSong(Base):
    __tablename__ = "album_songs"

    id = Column(TEXT, primary_key=True)

    album_id = Column(
        TEXT,
        ForeignKey("albums.id", ondelete="CASCADE"),
        nullable=False,
    )
    song_id = Column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        nullable=False,
    )

    # opzionale: traccia nell'album
    track_number = Column(Integer, nullable=True)
    # se vuoi supportare album multi-disc, puoi aggiungere:
    # disc_number = Column(Integer, nullable=True)

    # 🔹 lato Album / Song con back_populates
    album = relationship(
        "Album",
        back_populates="album_song_links",
    )
    song = relationship(
        "Song",
        back_populates="album_song_links",
    )
