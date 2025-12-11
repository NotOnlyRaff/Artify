from sqlalchemy import TEXT, Column, ForeignKey, VARCHAR
from sqlalchemy.orm import relationship
from models.base import Base


# Album <-> Artist (artisti accreditati dell'album)
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

    # ruolo sull'ALBUM (es. due primary artist, altri come 'guest')
    role = Column(VARCHAR(30), nullable=True)  # 'primary', 'guest', ecc.

    # 🔹 relazioni esplicite verso Album e Artist
    album = relationship(
        "Album",
        back_populates="album_artist_links",
    )
    artist = relationship(
        "Artist",
        back_populates="album_artist_links",
    )
