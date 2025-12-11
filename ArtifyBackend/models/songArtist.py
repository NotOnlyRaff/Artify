import enum

from sqlalchemy import TEXT, Column, ForeignKey, Enum as SAEnum, UniqueConstraint
from sqlalchemy.orm import relationship

from models.base import Base


class SongArtistRole(enum.Enum):
    PRIMARY = "primary"
    FEATURED = "featured"
    PRODUCER = "producer"
    MIXER = "mixer"
    WRITER = "writer"


class SongArtist(Base):
    __tablename__ = "song_artists"

    id = Column(TEXT, primary_key=True)

    song_id = Column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        nullable=False,
    )
    artist_id = Column(
        TEXT,
        ForeignKey("artists.id", ondelete="CASCADE"),
        nullable=False,
    )

    role = Column(
        SAEnum(SongArtistRole, name="song_artist_role"),
        nullable=False,
        default=SongArtistRole.PRIMARY,
    )

    __table_args__ = (
        UniqueConstraint("song_id", "artist_id", "role", name="uq_song_artist_role"),
    )

    song = relationship("Song", back_populates="song_artist_links")
    artist = relationship("Artist", back_populates="song_artist_links")

    def __repr__(self) -> str:
        return (
            f"<SongArtist song_id={self.song_id!r} "
            f"artist_id={self.artist_id!r} role={self.role.value!r}>"
        )
