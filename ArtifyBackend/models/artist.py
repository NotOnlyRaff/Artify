from sqlalchemy import TEXT, Column, VARCHAR
from sqlalchemy.orm import relationship
from models.base import Base


class Artist(Base):
    __tablename__ = "artists"

    id = Column(TEXT, primary_key=True)
    name = Column(VARCHAR(255), nullable=False)
    display_name = Column(VARCHAR(120), nullable=True)

    # Slug per URL / ricerche (unico ma non obbligatorio in MVP)
    slug = Column(
        VARCHAR(140),
        unique=True,
        index=True,
        nullable=True,
    )

    # Immagine profilo / cover dell’artista
    image_url = Column(TEXT, nullable=True)

    # Breve bio / descrizione (facoltativa)
    bio = Column(TEXT, nullable=True)

    # Paese / area geografica (opzionale ma utile per filtri futuri)
    country = Column(VARCHAR(80), nullable=True)

    # ---------- RELAZIONI ----------

    song_artist_links = relationship(
        "SongArtist",
        back_populates="artist",
        cascade="all, delete-orphan",
    )

    album_artist_links = relationship(
        "AlbumArtist",
        back_populates="artist",
        cascade="all, delete-orphan",
    )

    # M:N di comodo: canzoni dell'artista (SOLO LETTURA)
    songs = relationship(
        "Song",
        secondary="song_artists",
        viewonly=True,
        back_populates="artists",
        overlaps="song_artist_links,artist,song,artists",
    )

    # M:N di comodo: album dell'artista (SOLO LETTURA)
    albums = relationship(
        "Album",
        secondary="album_artists",
        viewonly=True,
        back_populates="artists",
        overlaps="album_artist_links,artist,album,albums",
    )
