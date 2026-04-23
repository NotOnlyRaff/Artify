import uuid

from sqlalchemy import TEXT, ForeignKey, UniqueConstraint
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin
from models.enums import SongArtistRole


class SongArtist(TimestampMixin, Base):
    __tablename__ = "song_artists"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    song_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        index=True,
    )
    artist_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("artists.id", ondelete="CASCADE"),
        index=True,
    )
    role: Mapped[SongArtistRole] = mapped_column(
        SAEnum(
            SongArtistRole,
            name="song_artist_role",
            values_callable=lambda x: [e.value for e in x],
            validate_strings=True,
        ),
        default=SongArtistRole.PRIMARY,
    )

    __table_args__ = (
        UniqueConstraint("song_id", "artist_id", "role", name="uq_song_artist_role"),
    )

    song: Mapped["Song"] = relationship(back_populates="song_artist_links")
    artist: Mapped["Artist"] = relationship(back_populates="song_artist_links")

    def __repr__(self) -> str:
        return (
            f"<SongArtist song_id={self.song_id!r} "
            f"artist_id={self.artist_id!r} role={self.role.value!r}>"
        )