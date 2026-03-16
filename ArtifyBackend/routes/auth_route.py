import mimetypes
import cloudinary
import cloudinary.uploader
from fastapi import APIRouter, Depends, status, UploadFile, File, HTTPException
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.user import User, UserRole
from schemas.user_schema import UserCreate, UserLogin, UserOut, UserPasswordChange, UserUpdate # Aggiunto UserUpdate
from services.auth_service import Auth
from pydantic import BaseModel

router = APIRouter(tags=["auth"])

class AuthResponse(BaseModel):
    token: str
    user: UserOut

# ---------- AUTH STANDARD ----------

@router.post("/signup", status_code=status.HTTP_201_CREATED, response_model=UserOut)
def signup_user(user: UserCreate, db: Session = Depends(get_db)):
    return Auth.signup(db, user)

@router.post("/login", response_model=AuthResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    return Auth.login(db, user)

@router.get("/", response_model=UserOut)
def current_user_data(db: Session = Depends(get_db), user_dict: dict = Depends(auth_middleware)):
    return Auth.get_current_user(db, user_dict["uid"])


# ---------- GESTIONE PROFILO (NUOVO) ----------

@router.post("/upload-profile-picture", response_model=UserOut)
async def upload_profile_pic(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware)
):
    """
    Carica la foto profilo su Cloudinary e restituisce l'URL.
    """
    # 1. Validazione tipo file
    content_type = file.content_type
    if not (content_type and content_type.startswith("image/")):
        raise HTTPException(status_code=400, detail="Il file deve essere un'immagine.")

    try:
        upload_res = cloudinary.uploader.upload(
            file.file,
            folder=f"artify/users/profiles/{user_dict['uid']}",
            overwrite=True,
            resource_type="image"
        )

        image_url = upload_res["secure_url"]

        user = db.query(User).filter(User.id == user_dict["uid"]).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        user.image_url = image_url
        db.commit()
        db.refresh(user)

        return user

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/update-profile", response_model=UserOut)
def update_profile(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware)
):
    """
    Aggiorna i metadati dell'utente (nome, email, profile_pic_url).
    """
    return Auth.update_user_profile(db, user_id=user_dict["uid"], update_data=payload)


# ---------- ADMIN AREA ----------

@router.get("/all", response_model=list[UserOut])
def get_all_users(
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_role([UserRole.ADMIN]))
):
    """
    Lista di tutti gli utenti. Solo per Admin.
    """
    return db.query(User).options(
        joinedload(User.favorite_songs),
        joinedload(User.artist_profile)
    ).all()

@router.delete("/delete/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    """
    Elimina un utente se il requester è admin oppure è lo stesso utente.
    """
    Auth.delete_user(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_id,
    )
    return

@router.patch("/change-password/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    user_id: str,
    payload: UserPasswordChange,
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    """
    Cambia la password di un utente se il requester è admin
    oppure è lo stesso utente.
    """
    Auth.change_user_password(
        db=db,
        requester_id=user_dict["uid"],
        target_user_id=user_id,
        payload=payload,
    )
    return