from sqlalchemy import TEXT, Column, VARCHAR, ForeignKey
from sqlalchemy.orm import relationship
from models.base import Base


class Artist(Base):
    __tablename__ = "artists"

    id = Column(TEXT, primary_key=True)
    name = Column(VARCHAR(255), nullable=False)
    display_name = Column(VARCHAR(120), nullable=True)
    
    slug = Column(
        VARCHAR(140),
        unique=True,
        index=True,
        nullable=True,
    )

    image_url = Column(TEXT, nullable=True)
    bio = Column(TEXT, nullable=True)
    country = Column(VARCHAR(80), nullable=True)

    # --- Relazioni ---

    # Relazione inversa verso l'utente
    user = relationship("User", back_populates="artist_profile", uselist=False, foreign_keys="User.artist_id", passive_deletes=True)

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

    songs = relationship(
        "Song",
        secondary="song_artists",
        viewonly=True,
        back_populates="artists",
        overlaps="song_artist_links,artist,song,artists",
    )

    albums = relationship(
        "Album",
        secondary="album_artists",
        viewonly=True,
        back_populates="artists",
        overlaps="album_artist_links,artist,album,albums",
    )
