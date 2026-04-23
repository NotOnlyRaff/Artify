from typing import Optional

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.enums import UserRole           # FIX: da enums.py
from models.user import User
from schemas.artist_schema import ArtistCreate, ArtistOut, ArtistUpdate
from services.artist_service import ArtistService

# FIX: cloudinary.config() rimosso — va configurato una sola volta in main.py.

router = APIRouter(tags=["artists"])


# ------------------------------------------------------------------ #
#  Ricerca                                                            #
# ------------------------------------------------------------------ #

@router.get("/search")
def search_artists(
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
    q: Optional[str] = None,
    song_id: Optional[str] = None,
    album_id: Optional[str] = None,
    # FIX: paginazione — il service ritorna dict {"items", "total", "limit", "offset"}.
    limit: int = 20,
    offset: int = 0,
):
    return ArtistService.search_artists(
        db=db, q=q, song_id=song_id, album_id=album_id,
        limit=limit, offset=offset,
    )


# ------------------------------------------------------------------ #
#  Lista                                                              #
# ------------------------------------------------------------------ #

@router.get("")
def list_artists(
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
    limit: int = 20,        # FIX: paginazione aggiunta.
    offset: int = 0,
):
    return ArtistService.list_artists(db, limit=limit, offset=offset)


# ------------------------------------------------------------------ #
#  Singolo artista                                                    #
# ------------------------------------------------------------------ #

@router.get("/{artist_id}", response_model=ArtistOut)
def get_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return ArtistService.get_artist_or_404(artist_id, db)


# ------------------------------------------------------------------ #
#  Upload immagine                                                    #
# ------------------------------------------------------------------ #

@router.post("/upload-image", status_code=status.HTTP_201_CREATED)
async def upload_artist_image(
    image: UploadFile = File(...),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    image_url = ArtistService.upload_artist_image(image, current_user)
    return {"image_url": image_url}


# ------------------------------------------------------------------ #
#  Creazione                                                          #
# ------------------------------------------------------------------ #

@router.post("", status_code=status.HTTP_201_CREATED, response_model=ArtistOut)
def create_artist(
    payload: ArtistCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return ArtistService.create_artist(payload=payload, db=db, current_user=current_user)


# ------------------------------------------------------------------ #
#  Aggiornamento                                                      #
# ------------------------------------------------------------------ #

@router.patch("/{artist_id}", response_model=ArtistOut)
def update_artist(
    artist_id: str,
    payload: ArtistUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return ArtistService.update_artist(
        artist_id=artist_id, payload=payload, db=db, current_user=current_user,
    )


# ------------------------------------------------------------------ #
#  Eliminazione                                                       #
# ------------------------------------------------------------------ #

@router.delete("/{artist_id}", status_code=status.HTTP_200_OK)
def delete_artist(
    artist_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role([UserRole.ADMIN])),
):
    ArtistService.delete_artist(artist_id, db)
    return {"message": "Artist deleted successfully"}