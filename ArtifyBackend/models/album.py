from sqlalchemy import TEXT, VARCHAR, Column, Date, Integer
from sqlalchemy.orm import relationship

from models.base import Base


class Album(Base):
    __tablename__ = "albums"

    # Di solito UUID in formato stringa
    id = Column(TEXT, primary_key=True)

    # Titolo dell'album
    title = Column(VARCHAR(200), nullable=False)

    # Copertina dell'album (URL su Cloudinary / S3 / ecc.)
    cover_url = Column(TEXT, nullable=True)

    # Data di rilascio (facoltativa, in V2 puoi anche non popolarla sempre)
    release_date = Column(Date, nullable=True)

    # Etichetta discografica / self released ecc. (facoltativa)
    label = Column(VARCHAR(120), nullable=True)

    # Eventuale campo denormalizzato: numero totale di tracce
    # (puoi anche calcolarlo via len(album.songs) invece di salvarlo)
    total_tracks = Column(Integer, nullable=True)

    # Tipo di album: 'album', 'single', 'ep', 'live', ecc. (opzionale)
    album_type = Column(VARCHAR(30), nullable=True)

    # ---------- RELAZIONI ----------

    # M:N con Song tramite AlbumSong
    songs = relationship(
      "Song",
      secondary="album_songs",   # nome della tabella di join
      back_populates="albums",
    )

    # M:N con Artist tramite AlbumArtist
    artists = relationship(
      "Artist",
      secondary="album_artists",  # nome della tabella di join
      back_populates="albums",
    )

    def __repr__(self) -> str:
        return f"<Album id={self.id!r} title={self.title!r}>"
