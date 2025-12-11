from sqlalchemy import TEXT, Column, VARCHAR, Date, Integer
from sqlalchemy.orm import relationship
from models.base import Base


class Song(Base):
    __tablename__ = "songs"

    id = Column(TEXT, primary_key=True)

    song_url = Column(TEXT, nullable=False)
    thumbnail_url = Column(TEXT, nullable=True)
    song_name = Column(VARCHAR(100), nullable=False)
    release_date = Column(Date, nullable=False)
    composer_name = Column(VARCHAR(120), nullable=False)
    producer_name = Column(VARCHAR(120), nullable=True)
    genre = Column(VARCHAR(80), nullable=True)
    lyrics = Column(TEXT, nullable=True)
    mood = Column(VARCHAR(50), nullable=True)
    duration_seconds = Column(Integer, nullable=True)

    # --- Relazioni ---

    song_artist_links = relationship(
        "SongArtist",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    artists = relationship(
        "Artist",
        secondary="song_artists",
        viewonly=True,
        back_populates="songs",
        overlaps="song_artist_links,artist,song,artists",
    )

    album_song_links = relationship(
        "AlbumSong",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    albums = relationship(
        "Album",
        secondary="album_songs",
        viewonly=True,
        back_populates="songs",
        overlaps="album_song_links,album,song,albums",
    )

    favorites = relationship(
        "Favorite",
        back_populates="song",
        cascade="all, delete-orphan",
    )
