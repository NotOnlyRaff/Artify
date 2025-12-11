from sqlalchemy import TEXT, Column, ForeignKey, Integer, UniqueConstraint
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

    track_number = Column(Integer, nullable=True)

    __table_args__ = (
        UniqueConstraint("album_id", "song_id", name="uq_album_song"),
    )

    album = relationship(
        "Album",
        back_populates="album_song_links",
    )
    song = relationship(
        "Song",
        back_populates="album_song_links",
    )
