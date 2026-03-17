from database import engine
from base import Base

# importa tutti i model, altrimenti non finiscono in metadata
from user import User
from artist import Artist
from album import Album
from song import Song
from favorite import Favorite
from songArtist import SongArtist
from albumArtist import AlbumArtist
from albumSong import AlbumSong

def init_db():
    Base.metadata.create_all(bind=engine)
    print("Schema creato correttamente su Supabase.")

if __name__ == "__main__":
    init_db()