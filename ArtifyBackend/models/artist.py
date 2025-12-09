from sqlalchemy import TEXT, VARCHAR, Column
from sqlalchemy.orm import relationship
from models.base import Base


class Artist(Base):
    __tablename__ = "artists"

    # Di solito UUID in formato stringa
    id = Column(TEXT, primary_key=True)

    # Nome principale dell'artista (obbligatorio)
    name = Column(VARCHAR(100), nullable=False)

    # Opzionale: variante "display" (es. con emoji, maiuscole strane, ecc.)
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

    # M:N con Song tramite tabella di join "song_artists"

    # in Artist
    song_artist_links = relationship(
        "SongArtist",
        back_populates="artist",
        cascade="all, delete-orphan",
    )
    
    songs = relationship(
        "Song",
        secondary="song_artists",   # nome della tabella di join
        back_populates="artists",
    )

    # M:N con Album tramite tabella di join "album_artists"
    albums = relationship(
        "Album",
        secondary="album_artists",
        back_populates="artists",
    )

    def __repr__(self) -> str:
        return f"<Artist id={self.id!r} name={self.name!r}>"
