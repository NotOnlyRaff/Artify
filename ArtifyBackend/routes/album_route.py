from typing import Optional

import cloudinary
import cloudinary.uploader
from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from core.config import settings
from database import get_db
from middleware.auth_middleware import auth_middleware
from schemas.album_schema import AlbumCreate, AlbumUpdate, AlbumOut
from services.album_service import AlbumService

router = APIRouter(tags=["albums"])

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)


@router.post("/upload-cover", status_code=status.HTTP_201_CREATED)
async def upload_album_cover(
    cover: UploadFile = File(...),
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    cover_url = AlbumService.upload_cover(
        cover=cover,
        db=db,
        requester_id=auth_details["uid"],
    )
    return {"cover_url": cover_url}


@router.post("", status_code=status.HTTP_201_CREATED, response_model=AlbumOut)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    return AlbumService.create_album(
        payload=payload,
        db=db,
        requester_id=auth_details["uid"],
    )


@router.get("", response_model=list[AlbumOut])
def list_albums(
    artist_id: Optional[str] = None,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    return AlbumService.list_albums(
        db=db,
        artist_id=artist_id,
    )


@router.get("/{album_id}", response_model=AlbumOut)
def get_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    return AlbumService.get_album_or_404(album_id, db)


@router.patch("/{album_id}", response_model=AlbumOut)
def update_album(
    album_id: str,
    payload: AlbumUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    return AlbumService.update_album(
        album_id=album_id,
        payload=payload,
        db=db,
        requester_id=auth_details["uid"],
    )


@router.delete("/{album_id}", status_code=status.HTTP_200_OK)
def delete_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    AlbumService.delete_album(
        album_id=album_id,
        db=db,
        requester_id=auth_details["uid"],
    )
    return {"message": "Album deleted successfully"}