from sqlalchemy import TEXT, Column, ForeignKey, VARCHAR, UniqueConstraint
from sqlalchemy.orm import relationship
from models.base import Base


class AlbumArtist(Base):
    __tablename__ = "album_artists"

    id = Column(TEXT, primary_key=True)

    album_id = Column(
        TEXT,
        ForeignKey("albums.id", ondelete="CASCADE"),
        nullable=False,
    )
    artist_id = Column(
        TEXT,
        ForeignKey("artists.id", ondelete="CASCADE"),
        nullable=False,
    )

    role = Column(VARCHAR(30), nullable=True)  # 'primary', 'guest', ecc.

    __table_args__ = (
        UniqueConstraint("album_id", "artist_id", "role", name="uq_album_artist_role"),
    )

    album = relationship(
        "Album",
        back_populates="album_artist_links",
    )
    artist = relationship(
        "Artist",
        back_populates="album_artist_links",
    )
