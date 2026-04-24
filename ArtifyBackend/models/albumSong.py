import uuid

from sqlalchemy import INTEGER, TEXT, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin


class AlbumSong(TimestampMixin, Base):
    __tablename__ = "album_songs"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    album_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("albums.id", ondelete="CASCADE"),
        index=True,
    )
    song_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        index=True,
    )
    track_number: Mapped[int] = mapped_column(INTEGER, nullable=False)

    __table_args__ = (
        UniqueConstraint("album_id", "song_id", name="uq_album_song"),
    )

    album: Mapped["Album"] = relationship(back_populates="album_song_links")
    song: Mapped["Song"] = relationship(back_populates="album_song_links")
