from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models.base import Base
from routes import album_route, artist_route, auth_route, song_route, songArtist_route
from database import engine

app = FastAPI()

# ⬇⬇ CORS (sviluppo: puoi anche usare "*" se vuoi semplificare)
origins = [
    "http://localhost:57605",  # porta di Flutter Web (controlla quella reale)
    "http://127.0.0.1:57605",
    "http://localhost:8000",   # opzionale, ma non fa male
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # in dev puoi mettere ["*"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_route.router, prefix="/auth")
app.include_router(song_route.router, prefix="/song")
app.include_router(album_route.router, prefix="/album")
app.include_router(artist_route.router, prefix="/artist")
app.include_router(songArtist_route.router, prefix="/song-artist")

@app.get("/health")
def health():
    return {"status": "ok"}
