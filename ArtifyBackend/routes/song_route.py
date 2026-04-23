import json
from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel, Field, ValidationError, model_validator
from sqlalchemy.orm import Session

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.enums import SongArtistRole, UserRole
from models.user import User
from schemas.favorite_schema import FavoriteCreate
from schemas.song_schema import SongArtistLinkIn, SongOut
from services.song_service import SongService

router = APIRouter(tags=["songs"])


# ------------------------------------------------------------------ #
#  Schema bridge per multipart upload                                #
# ------------------------------------------------------------------ #

class SongUploadForm(BaseModel):
    song_name: str = Field(min_length=1, max_length=100)
    release_date: date
    composer_id: Optional[str] = None
    composer_name: Optional[str] = Field(default=None, max_length=120)
    producer_id: Optional[str] = None
    producer_name: Optional[str] = Field(default=None, max_length=120)
    genre: Optional[str] = Field(default=None, max_length=80)
    lyrics: Optional[str] = None
    mood: Optional[str] = Field(default=None, max_length=50)
    duration_seconds: Optional[int] = Field(default=None, ge=0)
    artist_links: List[SongArtistLinkIn] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_composer(self):
        if not self.composer_id and not self.composer_name:
            raise ValueError("At least one of composer_id or composer_name must be provided")
        return self


# ------------------------------------------------------------------ #
#  Upload canzone                                                    #
# ------------------------------------------------------------------ #

@router.post("/upload", status_code=status.HTTP_201_CREATED, response_model=SongOut)
async def upload_song(
    song: UploadFile = File(...),
    thumbnail: UploadFile = File(...),
    song_name: str = Form(...),
    release_date: date = Form(...),
    composer_id: Optional[str] = Form(None),
    composer_name: Optional[str] = Form(None),
    producer_id: Optional[str] = Form(None),
    producer_name: Optional[str] = Form(None),
    genre: Optional[str] = Form(None),
    lyrics: Optional[str] = Form(None),
    mood: Optional[str] = Form(None),
    duration_seconds: Optional[int] = Form(None),
    artist_links_json: str = Form("[]"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    if not song.content_type or not song.content_type.startswith("audio/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an audio track",
        )
    if not thumbnail.content_type or not thumbnail.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thumbnail must be an image",
        )

    try:
        raw_links = json.loads(artist_links_json)
        if not isinstance(raw_links, list):
            raise ValueError
    except (json.JSONDecodeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="artist_links_json must be a valid JSON array",
        )

    try:
        artist_links: List[SongArtistLinkIn] = [
            SongArtistLinkIn(**link) for link in raw_links
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid artist_links format: {str(e)}",
        )

    if current_user.role == UserRole.ARTIST:
        if not current_user.artist_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No linked artist profile",
            )

        if current_user.artist_id not in {link.artist_id for link in artist_links}:
            artist_links.insert(
                0,
                SongArtistLinkIn(
                    artist_id=current_user.artist_id,
                    role=SongArtistRole.PRIMARY,
                ),
            )

    elif current_user.role == UserRole.ADMIN:
        if not artist_links:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must provide at least one artist",
            )

    try:
        song_form = SongUploadForm(
            song_name=song_name,
            release_date=release_date,
            composer_id=composer_id,
            composer_name=composer_name,
            producer_id=producer_id,
            producer_name=producer_name,
            genre=genre,
            lyrics=lyrics,
            mood=mood,
            duration_seconds=duration_seconds,
            artist_links=artist_links,
        )
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=e.errors(),
        )

    return SongService.upload_song(
        db=db,
        song_file=song,
        thumbnail_file=thumbnail,
        song_data=song_form,
    )


# ------------------------------------------------------------------ #
#  Lista canzoni                                                     #
# ------------------------------------------------------------------ #

@router.get("/list")
def list_songs(
    db: Session = Depends(get_db),
    limit: int = 20,
    offset: int = 0,
    _=Depends(auth_middleware),
):
    return SongService.get_all_songs(db, limit=limit, offset=offset)


# ------------------------------------------------------------------ #
#  Singola canzone                                                   #
# ------------------------------------------------------------------ #

@router.get("/{song_id}", response_model=SongOut)
def get_song(
    song_id: str,
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return SongService.get_song_by_id(db=db, song_id=song_id)


# ------------------------------------------------------------------ #
#  Preferiti                                                         #
# ------------------------------------------------------------------ #

@router.post("/favorite", status_code=status.HTTP_200_OK)
def favorite_song(
    payload: FavoriteCreate,
    db: Session = Depends(get_db),
    auth_data: dict = Depends(auth_middleware),
):
    is_added = SongService.toggle_favorite(db, auth_data["uid"], payload.song_id)
    return {
        "added": is_added,
        "message": "Song added to favorites" if is_added else "Song removed from favorites",
    }


# ------------------------------------------------------------------ #
#  Eliminazione                                                      #
# ------------------------------------------------------------------ #

@router.delete("/{song_id}", status_code=status.HTTP_200_OK)
def delete_song(
    song_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    SongService.delete_song(db=db, song_id=song_id, current_user=current_user)
    return {"message": "Song deleted successfully"}
