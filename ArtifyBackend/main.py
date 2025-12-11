from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models.base import Base
from routes import artist, auth, song, album, songArtist
from database import engine

app = FastAPI()

# ⬇⬇ CORS (sviluppo: puoi anche usare "*" se vuoi semplificare)
origins = [
    "http://localhost:53646",  # porta di Flutter Web (controlla quella reale)
    "http://127.0.0.1:53646",
    "http://localhost:8000",   # opzionale, ma non fa male
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # in dev puoi mettere ["*"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth")
app.include_router(song.router, prefix="/song")
app.include_router(album.router, prefix="/album")
app.include_router(artist.router, prefix="/artist")
app.include_router(songArtist.router)
Base.metadata.create_all(engine)
