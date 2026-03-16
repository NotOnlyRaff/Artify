import cloudinary
from typing import List, Optional

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from core.config import settings
from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.user import User, UserRole
from schemas.artist_schema import ArtistCreate, ArtistUpdate, ArtistOut
from services.artist_service import ArtistService

router = APIRouter(tags=["artists"])

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)


# ---------- SEARCH / FILTER ARTISTI ----------

@router.get(
    "/search",
    response_model=List[ArtistOut],
)
def search_artists(
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
    q: Optional[str] = None,
    song_id: Optional[str] = None,
    album_id: Optional[str] = None,
):
    return ArtistService.search_artists(
        db=db,
        q=q,
        song_id=song_id,
        album_id=album_id,
    )


# ---------- LISTA ARTISTI ----------

@router.get(
    "",
    response_model=List[ArtistOut],
)
def list_artists(
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return ArtistService.list_artists(db)


# ---------- GET SINGOLO ARTISTA ----------

@router.get(
    "/{artist_id}",
    response_model=ArtistOut,
)
def get_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return ArtistService.get_artist_or_404(artist_id, db)


# ---------- UPLOAD ARTIST IMAGE ----------

@router.post(
    "/upload-image",
    status_code=status.HTTP_201_CREATED,
)
async def upload_artist_image(
    image: UploadFile = File(...),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    image_url = ArtistService.upload_artist_image(image, current_user)
    return {"image_url": image_url}


# ---------- CREATE ARTIST ----------

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=ArtistOut,
)
def create_artist(
    payload: ArtistCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return ArtistService.create_artist(
        payload=payload,
        db=db,
        current_user=current_user,
    )


# ---------- UPDATE ARTIST ----------

@router.patch(
    "/{artist_id}",
    response_model=ArtistOut,
)
def update_artist(
    artist_id: str,
    payload: ArtistUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return ArtistService.update_artist(
        artist_id=artist_id,
        payload=payload,
        db=db,
        current_user=current_user,
    )


# ---------- DELETE ARTIST ----------

@router.delete(
    "/{artist_id}",
    status_code=status.HTTP_200_OK,
)
def delete_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN])),
):
    ArtistService.delete_artist(artist_id, db)
    return {"message": "Artist deleted successfully"}