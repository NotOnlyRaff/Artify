from sqlalchemy import TEXT, Column, VARCHAR, Date, Integer
from sqlalchemy.orm import relationship
from models.base import Base


class Album(Base):
    __tablename__ = "albums"

    id = Column(TEXT, primary_key=True)

    title = Column(VARCHAR(200), nullable=False)
    cover_url = Column(TEXT, nullable=True)
    release_date = Column(Date, nullable=True)
    label = Column(VARCHAR(120), nullable=True)
    total_tracks = Column(Integer, nullable=True)
    album_type = Column(VARCHAR(30), nullable=True)

    # --- Relazioni ---

    # Join esplicita verso artisti
    album_artist_links = relationship(
        "AlbumArtist",
        back_populates="album",
        cascade="all, delete-orphan",
    )

    # Lista di artisti (sola lettura, via tabella di join)
    artists = relationship(
        "Artist",
        secondary="album_artists",
        viewonly=True,
        back_populates="albums",
        overlaps="album_artist_links,artist,album,artists",
    )

    # Join esplicita verso canzoni
    album_song_links = relationship(
        "AlbumSong",
        back_populates="album",
        cascade="all, delete-orphan",
    )

    # Lista di canzoni (sola lettura, via tabella di join)
    songs = relationship(
        "Song",
        secondary="album_songs",
        viewonly=True,
        back_populates="albums",
        overlaps="album_song_links,album,song,albums",
    )
