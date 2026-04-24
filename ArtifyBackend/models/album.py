import uuid
from datetime import date
from typing import List, Optional

from sqlalchemy import TEXT, VARCHAR
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin


class Album(TimestampMixin, Base):
    __tablename__ = "albums"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    title: Mapped[str] = mapped_column(VARCHAR(200))
    cover_url: Mapped[Optional[str]] = mapped_column(TEXT)
    release_date: Mapped[Optional[date]]
    label: Mapped[Optional[str]] = mapped_column(VARCHAR(120))
    album_type: Mapped[Optional[str]] = mapped_column(VARCHAR(30))
    genre: Mapped[Optional[str]] = mapped_column(VARCHAR(30))

    # --- Relazioni (source of truth) ---

    album_artist_links: Mapped[List["AlbumArtist"]] = relationship(
        back_populates="album",
        cascade="all, delete-orphan",
    )
    album_song_links: Mapped[List["AlbumSong"]] = relationship(
        back_populates="album",
        cascade="all, delete-orphan",
        order_by="AlbumSong.track_number",
    )

    def __repr__(self) -> str:
        return f"<Album id={self.id!r} title={self.title!r}>"
