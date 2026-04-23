from typing import Optional

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.enums import UserRole           # FIX: coerente con gli altri file
from models.user import User
from schemas.album_schema import AlbumCreate, AlbumOut, AlbumUpdate
from services.album_service import AlbumService

# FIX: cloudinary.config() rimosso — va configurato una sola volta in main.py.

router = APIRouter(tags=["albums"])


# ------------------------------------------------------------------ #
#  Upload cover                                                       #
# ------------------------------------------------------------------ #

@router.post("/upload-cover", status_code=status.HTTP_201_CREATED)
async def upload_album_cover(
    cover: UploadFile = File(...),
    db: Session = Depends(get_db),
    # FIX: solo ARTIST e ADMIN possono caricare cover — il vecchio codice
    # usava auth_middleware generico senza controllo ruolo.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    cover_url = AlbumService.upload_cover(
        cover=cover,
        db=db,
        requester_id=current_user.id,
    )
    return {"cover_url": cover_url}


# ------------------------------------------------------------------ #
#  Creazione                                                          #
# ------------------------------------------------------------------ #

@router.post("", status_code=status.HTTP_201_CREATED, response_model=AlbumOut)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    # FIX: richiedeva solo auth_middleware, ora require_role ARTIST/ADMIN.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return AlbumService.create_album(
        payload=payload,
        db=db,
        requester_id=current_user.id,
    )


# ------------------------------------------------------------------ #
#  Lista                                                              #
# ------------------------------------------------------------------ #

@router.get("")
def list_albums(
    artist_id: Optional[str] = None,
    db: Session = Depends(get_db),
    limit: int = 20,        # FIX: paginazione — il service ritorna dict con total.
    offset: int = 0,
    _=Depends(auth_middleware),
):
    # FIX: response_model rimosso — il service ritorna dict paginato.
    # Usare Page[AlbumOut] quando il generico sarà disponibile.
    return AlbumService.list_albums(db=db, artist_id=artist_id, limit=limit, offset=offset)


# ------------------------------------------------------------------ #
#  Singolo album                                                      #
# ------------------------------------------------------------------ #

@router.get("/{album_id}", response_model=AlbumOut)
def get_album(
    album_id: str,
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return AlbumService.get_album_or_404(album_id, db)


# ------------------------------------------------------------------ #
#  Aggiornamento                                                      #
# ------------------------------------------------------------------ #

@router.patch("/{album_id}", response_model=AlbumOut)
def update_album(
    album_id: str,
    payload: AlbumUpdate,
    db: Session = Depends(get_db),
    # FIX: require_role invece di auth_middleware generico.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    return AlbumService.update_album(
        album_id=album_id,
        payload=payload,
        db=db,
        requester_id=current_user.id,
    )


# ------------------------------------------------------------------ #
#  Eliminazione                                                       #
# ------------------------------------------------------------------ #

@router.delete("/{album_id}", status_code=status.HTTP_200_OK)
def delete_album(
    album_id: str,
    db: Session = Depends(get_db),
    # FIX: require_role invece di auth_middleware generico.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    AlbumService.delete_album(
        album_id=album_id,
        db=db,
        requester_id=current_user.id,
    )
    return {"message": "Album deleted successfully"}