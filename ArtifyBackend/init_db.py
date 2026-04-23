from database import engine
from models.base import Base

import models.album
import models.albumArtist
import models.albumSong
import models.artist
import models.favorite
import models.song
import models.songArtist
import models.user


def init_db():
    Base.metadata.create_all(bind=engine)
    print("Schema creato correttamente sul database configurato.")


if __name__ == "__main__":
    init_db()
