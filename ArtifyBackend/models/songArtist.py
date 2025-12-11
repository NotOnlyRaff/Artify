# models/song_artist.py

import enum

from sqlalchemy import TEXT, Column, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import relationship

from models.base import Base


class SongArtistRole(enum.Enum):
    PRIMARY = "primary"        # artista principale
    FEATURED = "featured"      # feat.
    PRODUCER = "producer"      # producer
    MIXER = "mixer"            # mixer
    WRITER = "writer"          # autore / songwriter


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

    # Il ruolo dell'artista rispetto a QUEL brano
    role = Column(
        SAEnum(SongArtistRole, name="song_artist_role"),
        nullable=False,
        default=SongArtistRole.PRIMARY,
    )

    # Relazioni verso i due estremi
    song = relationship("Song", back_populates="song_artist_links")
    artist = relationship("Artist", back_populates="song_artist_links")

    def __repr__(self) -> str:
        return (
            f"<SongArtist song_id={self.song_id!r} "
            f"artist_id={self.artist_id!r} role={self.role.value!r}>"
        )
