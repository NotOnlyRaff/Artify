# routes/song.py

import json
import uuid
from datetime import date
from typing import List

import cloudinary
import cloudinary.uploader
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware
from models.favorite import Favorite
from models.song import Song
from models.songArtist import SongArtist, SongArtistRole
from schemas.favorite_song import FavoriteSong
from schemas.song import SongOut


router = APIRouter(tags=["songs"])

# Tipi MIME che accettiamo per l'audio
ALLOWED_CONTENT_TYPES = {
    "audio/mpeg",
    "audio/wav",
    "audio/x-wav",
    "audio/flac",
    "audio/ogg",
    "audio/x-aac",
    "application/octet-stream",  # fallback quando il client non setta bene il type
}

# TODO: in produzione spostare queste in variabili d'ambiente
cloudinary.config(
    cloud_name="dgjqxcl8u",
    api_key="152778217772653",
    api_secret="BscHrsDSpoGrKfEJhn2_X1WIolc",  # metti la tua ma NON committarla
    secure=True,
)


# ---------- UPLOAD SONG ----------


@router.post(
    "/upload",
    status_code=status.HTTP_201_CREATED,
    response_model=SongOut,
)
async def upload_song(
    song: UploadFile = File(...),
    thumbnail: UploadFile = File(...),
    song_name: str = Form(...),
    release_date: date = Form(...),
    composer_name: str = Form(...),
    producer_name: str | None = Form(None),
    genre: str | None = Form(None),
    lyrics: str | None = Form(None),
    mood: str | None = Form(None),
    # 👇 array di ID artista, serializzato come JSON dalla mobile/web app
    artist_ids_json: str | None = Form(None),
    db: Session = Depends(get_db),
    auth_dict: dict = Depends(auth_middleware),
):
    """
    Carica una nuova traccia su Cloudinary + DB.

    - `song`      : file audio
    - `thumbnail` : cover della track
    - metadata    : nome, data di uscita, compositore, ecc.
    - `artist_ids_json`: JSON array di artist_id da collegare come PRIMARY
    """

    if song.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid audio file type",
        )

    song_id = str(uuid.uuid4())

    # 1) upload su Cloudinary
    try:
        song_res = cloudinary.uploader.upload(
            song.file,
            resource_type="auto",
            folder=f"songs/{song_id}",
        )
        thumbnail_res = cloudinary.uploader.upload(
            thumbnail.file,
            resource_type="image",
            folder=f"songs/{song_id}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading media file: {e}",
        )

    # 2) creazione record Song
    db_song = Song(
        id=song_id,
        song_name=song_name,
        song_url=song_res["url"],
        thumbnail_url=thumbnail_res["url"],
        release_date=release_date,
        composer_name=composer_name,
        producer_name=producer_name,
        genre=genre,
        lyrics=lyrics,
        mood=mood,
        # duration_seconds: per ora null, potrai popolarlo lato worker/cron
    )

    db.add(db_song)
    db.flush()  # ora esiste in sessione, possiamo creare i link

    # 3) crea le righe SongArtist (se sono stati passati degli artist_id)
    artist_ids: list[str] = []
    if artist_ids_json:
        try:
            parsed = json.loads(artist_ids_json)
            if isinstance(parsed, list):
                artist_ids = [str(a) for a in parsed if a]
        except json.JSONDecodeError:
            # se arriva corrotto, non blocchiamo l'upload ma logghiamo
            artist_ids = []

    for artist_id in artist_ids:
        link = SongArtist(
            id=str(uuid.uuid4()),
            song_id=song_id,
            artist_id=artist_id,
            role=SongArtistRole.PRIMARY,  # per ora tutti PRIMARY
        )
        db.add(link)

    db.commit()
    db.refresh(db_song)

    return db_song


# ---------- DELETE SONG ----------


@router.delete(
    "/{song_id}",
    status_code=status.HTTP_200_OK,
)
def delete_song(
    song_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
) -> dict:
    song = db.query(Song).filter(Song.id == song_id).first()
    if not song:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Song not found",
        )

    db.delete(song)
    db.commit()
    return {"message": "Song deleted successfully"}


# ---------- LISTA DI TUTTE LE SONG ----------


@router.get(
    "/list",
    response_model=List[SongOut],
)
def list_songs(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Restituisce tutte le canzoni disponibili.

    In futuro puoi filtrare per:
    - release_date <= today (solo brani pubblicati)
    - artista / album / genere / mood, ecc.
    """
    songs = (
        db.query(Song)
        .options(
            # 🔹 carica i link song–artist + artista
            joinedload(Song.song_artist_links)
            .joinedload(SongArtist.artist),

            # 🔹 carica gli album collegati
            joinedload(Song.albums),
        )
        .all()
    )
    return songs

# ---------- TOGGLE FAVORITE ----------


@router.post("/favorite")
def favorite_song(
    song: FavoriteSong,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Aggiunge/rimuove una song dai preferiti dell'utente.

    Ritorna:
    - {"message": True}  => ora è tra i preferiti
    - {"message": False} => è stata rimossa dai preferiti
    """
    user_id = auth_details["uid"]

    fav_song = (
        db.query(Favorite)
        .filter(
            Favorite.song_id == song.song_id,
            Favorite.user_id == user_id,
        )
        .first()
    )

    if fav_song:
        db.delete(fav_song)
        db.commit()
        return {"message": False}
    else:
        new_fav = Favorite(
            id=str(uuid.uuid4()),
            song_id=song.song_id,
            user_id=user_id,
        )
        db.add(new_fav)
        db.commit()
        return {"message": True}


# ---------- LISTA SONG PREFERITE ----------


@router.get(
    "/list/favorites",
    response_model=List[SongOut],
)
def list_fav_songs(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Lista dei brani preferiti dell'utente corrente.

    Prima prende le righe Favorite, poi mappa alle Song col joinedload.
    """
    user_id = auth_details["uid"]

    fav_rows = (
        db.query(Favorite)
        .filter(Favorite.user_id == user_id)
        .options(
            joinedload(Favorite.song)
            .joinedload(Song.song_artist_links)
            .joinedload(SongArtist.artist),
            joinedload(Favorite.song)
            .joinedload(Song.albums),
        )
        .all()
    )

    songs = [fav.song for fav in fav_rows]
    return songs
