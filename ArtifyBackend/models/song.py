from sqlalchemy import TEXT, Column, VARCHAR, Date, Integer
from sqlalchemy.orm import relationship
from models.base import Base
from models.songArtist import SongArtist
from models.albumSong import AlbumSong  # <--- IMPORTANTE


class Song(Base):
    __tablename__ = "songs"

    id = Column(TEXT, primary_key=True)

    # URL del file audio (Cloudinary / S3 / ecc.)
    song_url = Column(TEXT, nullable=False)

    # Cover specifica della traccia (può coincidere o meno con quella dell'album)
    thumbnail_url = Column(TEXT, nullable=True)

    # Titolo del brano
    song_name = Column(VARCHAR(100), nullable=False)

    # Data di uscita (può essere nel futuro per release programmate)
    release_date = Column(Date, nullable=False)

    # Compositore del brano (autore "musicale/testo" principale)
    composer_name = Column(VARCHAR(120), nullable=False)

    # Produttore / compositore del beat (es. producer, beatmaker)
    producer_name = Column(VARCHAR(120), nullable=True)

    # Genere principale del brano (es. "Hip-Hop", "R&B", "Drill")
    genre = Column(VARCHAR(80), nullable=True)

    # Testo completo del brano
    lyrics = Column(TEXT, nullable=True)

    # Mood / vibe del pezzo (es. "chill", "sad", "club", "motivational")
    mood = Column(VARCHAR(50), nullable=True)

    # Durata in secondi (opzionale, puoi popolarla in futuro)
    duration_seconds = Column(Integer, nullable=True)

    # ---------- RELAZIONI ----------

    # Join table con artisti (lato forte)
    song_artist_links = relationship(
        "SongArtist",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    # M:N di comodo: lista artisti (SOLO LETTURA)
    artists = relationship(
        "Artist",
        secondary="song_artists",
        viewonly=True,
        back_populates="songs",
        overlaps="song_artist_links,artist,song,artists",
    )

    # Join table con album
    album_song_links = relationship(
        "AlbumSong",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    # M:N di comodo: lista album (SOLO LETTURA)
    albums = relationship(
        "Album",
        secondary="album_songs",
        viewonly=True,
        back_populates="songs",
        overlaps="album_song_links,album,song,albums",
    )

    favorites = relationship(
        "Favorite",              # usa il nome reale della classe
        back_populates="song",   # deve combaciare con quel back_populates
        cascade="all, delete-orphan",
    )
