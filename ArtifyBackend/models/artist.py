import uuid
from typing import List, Optional

from sqlalchemy import TEXT, VARCHAR
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin


class Artist(TimestampMixin, Base):
    __tablename__ = "artists"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(VARCHAR(255))
    display_name: Mapped[Optional[str]] = mapped_column(VARCHAR(120))
    slug: Mapped[Optional[str]] = mapped_column(VARCHAR(140), unique=True, index=True)
    image_url: Mapped[Optional[str]] = mapped_column(TEXT)
    bio: Mapped[Optional[str]] = mapped_column(TEXT)
    country: Mapped[Optional[str]] = mapped_column(VARCHAR(80))

    # --- Relazioni ---

    # 1:1 inversa verso User
    user: Mapped[Optional["User"]] = relationship(
        back_populates="artist_profile",
        uselist=False,
        foreign_keys="User.artist_id",
        passive_deletes=True,
    )

    # Canzoni dove questo artista è composer/producer (FK su Song)
    composed_songs: Mapped[List["Song"]] = relationship(
        foreign_keys="Song.composer_id",
        back_populates="composer",
    )
    produced_songs: Mapped[List["Song"]] = relationship(
        foreign_keys="Song.producer_id",
        back_populates="producer",
    )

    # Source of truth per i link song <-> artist
    song_artist_links: Mapped[List["SongArtist"]] = relationship(
        back_populates="artist",
        cascade="all, delete-orphan",
    )

    # Source of truth per i link album <-> artist
    album_artist_links: Mapped[List["AlbumArtist"]] = relationship(
        back_populates="artist",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Artist id={self.id!r} name={self.name!r}>"