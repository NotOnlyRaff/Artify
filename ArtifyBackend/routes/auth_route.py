import cloudinary.uploader
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.enums import UserRole           # FIX: da enums.py
from models.user import User
from schemas.user_schema import (
    UserCreate, UserLogin, UserOut, UserPasswordChange, UserUpdate,
)
from services.auth_service import Auth

router = APIRouter(tags=["auth"])


class AuthResponse(BaseModel):
    token: str
    user: UserOut


# ------------------------------------------------------------------ #
#  Auth standard                                                      #
# ------------------------------------------------------------------ #

@router.post("/signup", status_code=status.HTTP_201_CREATED, response_model=UserOut)
def signup_user(user: UserCreate, db: Session = Depends(get_db)):
    return Auth.signup(db, user)


@router.post("/login", response_model=AuthResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    return Auth.login(db, user)


@router.get("/", response_model=UserOut)
def current_user_data(
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    return Auth.get_current_user(db, user_dict["uid"])


# ------------------------------------------------------------------ #
#  Gestione profilo                                                   #
# ------------------------------------------------------------------ #

@router.post("/upload-profile-picture", response_model=UserOut)
async def upload_profile_pic(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    content_type = file.content_type
    if not (content_type and content_type.startswith("image/")):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image",
        )

    try:
        upload_res = cloudinary.uploader.upload(
            file.file,
            folder=f"artify/users/profiles/{user_dict['uid']}",
            overwrite=True,
            resource_type="image",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Image upload failed: {str(e)}",
        )

    image_url = upload_res.get("secure_url")
    if not image_url:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Upload succeeded but no secure_url returned",
        )

    # FIX: aggiorna image_url via service invece di scrivere direttamente nel DB.
    # FIX: requester_id == target_user_id — l'utente aggiorna se stesso.
    return Auth.update_user_profile(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_dict["uid"],
        update_data=UserUpdate(image_url=image_url),
    )


@router.patch("/update-profile", response_model=UserOut)
def update_profile(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    # FIX: aggiunta firma corretta con requester_id e target_user_id.
    # Il vecchio codice passava user_id= come kwarg sbagliato.
    return Auth.update_user_profile(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_dict["uid"],
        update_data=payload,
    )


# ------------------------------------------------------------------ #
#  Admin area                                                         #
# ------------------------------------------------------------------ #

@router.get("/all", response_model=list[UserOut])
def get_all_users(
    db: Session = Depends(get_db),
    # FIX: aggiunto limit/offset per evitare di caricare tutto il DB.
    limit: int = 20,
    offset: int = 0,
    current_admin: User = Depends(require_role([UserRole.ADMIN])),
):
    # FIX: rimosso joinedload(User.favorite_songs) — relazione eliminata dal model.
    total = db.query(User).count()
    users = db.query(User).offset(offset).limit(limit).all()
    return users


@router.delete("/delete/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    Auth.delete_user(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_id,
    )


@router.patch("/change-password/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    user_id: str,
    payload: UserPasswordChange,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    Auth.change_user_password(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_id,
        payload=payload,
    )