from sqlalchemy import TEXT, Column, VARCHAR, Date, Integer
from sqlalchemy.orm import relationship
from models.base import Base
from models.albumArtist import AlbumArtist
from models.albumSong import AlbumSong  # <--- IMPORTANTE


class Album(Base):
    __tablename__ = "albums"

    # Di solito UUID in formato stringa
    id = Column(TEXT, primary_key=True)

    # Titolo dell'album
    title = Column(VARCHAR(200), nullable=False)

    # Copertina dell'album (URL su Cloudinary / S3 / ecc.)
    cover_url = Column(TEXT, nullable=True)

    # Data di rilascio (facoltativa)
    release_date = Column(Date, nullable=True)

    # Etichetta discografica / self released ecc. (facoltativa)
    label = Column(VARCHAR(120), nullable=True)

    # Totale tracce (opzionale, puoi anche calcolarlo via len(album.songs))
    total_tracks = Column(Integer, nullable=True)

    # Tipo di album: 'album', 'single', 'ep', 'live', ecc. (opzionale)
    album_type = Column(VARCHAR(30), nullable=True)

    # ---------- RELAZIONI ----------

    # 🔹 Join table con artisti (lato che "scrive")
    album_artist_links = relationship(
        "AlbumArtist",
        back_populates="album",
        cascade="all, delete-orphan",
    )

    # M:N di comodo: lista di artisti dell'album (SOLO LETTURA)
    artists = relationship(
        "Artist",
        secondary="album_artists",
        viewonly=True,
        back_populates="albums",
        overlaps="album_artist_links,artist,album,artists",
    )

    # 🔹 Join table con canzoni (lato che "scrive")
    album_song_links = relationship(
        "AlbumSong",
        back_populates="album",
        cascade="all, delete-orphan",
    )

    # M:N di comodo: lista canzoni dell'album (SOLO LETTURA)
    songs = relationship(
        "Song",
        secondary="album_songs",
        viewonly=True,
        back_populates="albums",
        overlaps="album_song_links,album,song,albums",
    )
