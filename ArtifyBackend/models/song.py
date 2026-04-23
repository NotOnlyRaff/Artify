import uuid
from datetime import date
from typing import List, Optional

from sqlalchemy import TEXT, VARCHAR, CheckConstraint, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin


class Song(TimestampMixin, Base):
    __tablename__ = "songs"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    song_url: Mapped[str] = mapped_column(TEXT)
    thumbnail_url: Mapped[Optional[str]] = mapped_column(TEXT)
    song_name: Mapped[str] = mapped_column(VARCHAR(100))
    release_date: Mapped[date]

    # FK opzionali verso Artist
    composer_id: Mapped[Optional[str]] = mapped_column(
        TEXT,
        ForeignKey("artists.id", ondelete="SET NULL"),
        index=True,
    )
    producer_id: Mapped[Optional[str]] = mapped_column(
        TEXT,
        ForeignKey("artists.id", ondelete="SET NULL"),
        index=True,
    )

    # Fallback testuale per autori/produttori non presenti nel catalogo
    composer_name: Mapped[Optional[str]] = mapped_column(VARCHAR(120))
    producer_name: Mapped[Optional[str]] = mapped_column(VARCHAR(120))

    genre: Mapped[Optional[str]] = mapped_column(VARCHAR(80))
    lyrics: Mapped[Optional[str]] = mapped_column(TEXT)
    mood: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    duration_seconds: Mapped[Optional[int]]

    __table_args__ = (
        CheckConstraint(
            "(composer_id IS NOT NULL) OR (composer_name IS NOT NULL)",
            name="ck_song_composer_present",
        ),
    )

    # --- Relazioni principali (source of truth) ---

    song_artist_links: Mapped[List["SongArtist"]] = relationship(
        back_populates="song",
        cascade="all, delete-orphan",
    )
    album_song_links: Mapped[List["AlbumSong"]] = relationship(
        back_populates="song",
        cascade="all, delete-orphan",
    )
    favorites: Mapped[List["Favorite"]] = relationship(
        back_populates="song",
        cascade="all, delete-orphan",
    )

    # --- Relazioni verso Artist per composer/producer ---

    composer: Mapped[Optional["Artist"]] = relationship(
        foreign_keys="Song.composer_id",
        back_populates="composed_songs",
    )
    producer: Mapped[Optional["Artist"]] = relationship(
        foreign_keys="Song.producer_id",
        back_populates="produced_songs",
    )

    def __repr__(self) -> str:
        return f"<Song id={self.id!r} song_name={self.song_name!r}>"