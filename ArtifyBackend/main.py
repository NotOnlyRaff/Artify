import cloudinary
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from models.base import Base
from database import engine
from core.config import settings

# Import modelli — necessario per la model discovery di SQLAlchemy/Alembic.
# Senza questi import, Base.metadata non conosce le tabelle.
import models.album
import models.albumArtist
import models.albumSong
import models.artist
import models.favorite
import models.song
import models.songArtist
import models.user

from routes import album_route, artist_route, auth_route, song_route, songArtist_route


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Cloudinary configurato una sola volta all'avvio.
    
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )
    
    Base.metadata.create_all(bind=engine)##localtest
    yield


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # dev only — in prod leggi da settings
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_route.router, prefix="/auth")
app.include_router(song_route.router, prefix="/songs")
app.include_router(album_route.router, prefix="/albums")
app.include_router(artist_route.router, prefix="/artists")
app.include_router(songArtist_route.router, prefix="/song-artists")


@app.get("/health")
def health():
    return {"status": "ok"}