from fastapi import APIRouter, Depends, File, Form, UploadFile, status, HTTPException
from sqlalchemy.orm import Session
from datetime import date
import json

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.user import User, UserRole
from schemas.song_schema import SongOut
from schemas.favorite_schema import FavoriteCreate
from services.song_service import SongService

router = APIRouter(tags=["songs"])

@router.post("/upload", status_code=status.HTTP_201_CREATED, response_model=SongOut)
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
    artist_ids_json: str = Form("[]"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    # Validazione rapida tipo file
    if not song.content_type or not song.content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="File must be an audio track")
    #Validazione Copertina
    if not thumbnail.content_type or not thumbnail.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Thumbnail must be an image")


    # Parsing ID Artisti
    try:
        parsed_artist_ids = json.loads(artist_ids_json)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="artist_ids_json must be valid JSON")

    if not isinstance(parsed_artist_ids, list):
        raise HTTPException(status_code=400, detail="artist_ids_json must be a JSON array")
    
    # normalizzazione: stringhe, non vuoti, deduplica mantenendo ordine
    artist_ids = []
    seen = set()
    for artist_id in parsed_artist_ids:
        if not isinstance(artist_id, str) or not artist_id.strip():
            raise HTTPException(status_code=400, detail="Each artist_id must be a non-empty string")
        if artist_id not in seen:
            seen.add(artist_id)
            artist_ids.append(artist_id)

    # regola di ownership
    if current_user.role == UserRole.ARTIST:
        if not current_user.artist_id:
            raise HTTPException(
                status_code=403,
                detail="Current artist user has no linked artist profile"
            )

        # forza il proprio artist_id nella song
        if current_user.artist_id not in artist_ids:
            artist_ids.insert(0, current_user.artist_id)

    elif current_user.role == UserRole.ADMIN:
        if not artist_ids:
            raise HTTPException(
                status_code=400,
                detail="Admin must provide at least one artist_id"
            )

    song_data = {
        "song_name": song_name,
        "release_date": release_date,
        "composer_name": composer_name,
        "producer_name": producer_name,
        "genre": genre,
        "lyrics": lyrics,
        "mood": mood,
    }

    return SongService.upload_song(
        db=db,
        song_file=song,
        thumbnail_file=thumbnail,
        song_data=song_data,
        artist_ids=artist_ids,
    )


@router.get("/list", response_model=list[SongOut])
def list_songs(
    db: Session = Depends(get_db),
    _ = Depends(auth_middleware) # Chiunque loggato può vedere la lista
):
    return SongService.get_all_songs(db)

@router.post("/favorite")
def favorite_song(
    payload: FavoriteCreate,
    db: Session = Depends(get_db),
    auth_data: dict = Depends(auth_middleware)
):
    is_added = SongService.toggle_favorite(db, auth_data["uid"], payload.song_id)
    return {"message": is_added}


@router.delete("/{song_id}", status_code=status.HTTP_200_OK)
def delete_song(
    song_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    SongService.delete_song(
        db=db,
        song_id=song_id,
        current_user=current_user,
    )
    return {"message": "Song deleted successfully"}