from sqlalchemy import TEXT, Column, ForeignKey, VARCHAR
from models.base import Base


# Album <-> Artist (artisti accreditati dell'album)
class AlbumArtist(Base):
    __tablename__ = "album_artists"

    album_id  = Column(TEXT, ForeignKey("albums.id"), primary_key=True)
    artist_id = Column(TEXT, ForeignKey("artists.id"), primary_key=True)

    # ruolo sull'ALBUM (es. due primary artist, altri come 'guest')
    role = Column(VARCHAR(30), nullable=True)  # 'primary', 'guest'