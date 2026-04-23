import uuid

from models.enums import AlbumArtistRole
from models.base import Base, TimestampMixin
from sqlalchemy import TEXT, ForeignKey, UniqueConstraint
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship




class AlbumArtist(TimestampMixin, Base):
    __tablename__ = "album_artists"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    album_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("albums.id", ondelete="CASCADE"),
        index=True,
    )
    artist_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("artists.id", ondelete="CASCADE"),
        index=True,
    )
    role: Mapped[AlbumArtistRole] = mapped_column(
        SAEnum(
            AlbumArtistRole,
            name="album_artist_role",
            values_callable=lambda x: [e.value for e in x],
            validate_strings=True,
        ),
        default=AlbumArtistRole.PRIMARY,
    )

    __table_args__ = (
        UniqueConstraint("album_id", "artist_id", "role", name="uq_album_artist_role"),
    )

    album: Mapped["Album"] = relationship(back_populates="album_artist_links")
    artist: Mapped["Artist"] = relationship(back_populates="album_artist_links")