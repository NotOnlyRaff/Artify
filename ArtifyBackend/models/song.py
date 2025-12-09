from sqlalchemy import TEXT, VARCHAR, Column, Integer, Date
from sqlalchemy.orm import relationship

from models.base import Base


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

       # LINK 1:N verso l’association object (SongArtist)
    song_artist_links = relationship(
        "SongArtist",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    # M:N con Artist tramite SongArtist
    artists = relationship(
        "Artist",
        secondary="song_artists",   # nome della tabella di join
        back_populates="songs",
    )

    # M:N con Album tramite AlbumSong
    albums = relationship(
        "Album",
        secondary="album_songs",    # nome della tabella di join
        back_populates="songs",
    )

    # 1:N con Favorite (User <-> Song M:N tramite Favorite)
    favorites = relationship(
        "Favorite",
        back_populates="song",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Song id={self.id!r} name={self.song_name!r} release_date={self.release_date!r}>"
