import uuid
import bcrypt
import jwt

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware
from models.user import User

from schemas.user import UserCreate, UserLogin, UserOut  # 👈 nuovi schemi Pydantic
from pydantic import BaseModel

router = APIRouter()


# ---------- SCHEMA DI RISPOSTA LOGIN ----------

class AuthResponse(BaseModel):
    token: str
    user: UserOut


# ---------- SIGNUP ----------

@router.post("/signup", status_code=status.HTTP_201_CREATED, response_model=UserOut)
def signup_user(
    user: UserCreate,
    db: Session = Depends(get_db),
):
    # check if the user already exists in db
    user_db = db.query(User).filter(User.email == user.email).first()

    if user_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with the same email already exists!",
        )

    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())

    user_db = User(
        id=str(uuid.uuid4()),
        email=user.email,
        password=hashed_pw,
        name=user.name,
    )

    db.add(user_db)
    db.commit()
    db.refresh(user_db)

    # grazie al response_model=UserOut non esponi mai la password
    return user_db


# ---------- LOGIN ----------

@router.post("/login", response_model=AuthResponse)
def login_user(
    user: UserLogin,
    db: Session = Depends(get_db),
):
    # check if a user with same email already exists
    user_db = db.query(User).filter(User.email == user.email).first()

    if not user_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email does not exist!",
        )

    # password matching or not
    is_match = bcrypt.checkpw(user.password.encode(), user_db.password)

    if not is_match:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect password!",
        )

    # in produzione: usa SECRET dal config + algoritmo esplicito
    token = jwt.encode(
        {"id": user_db.id},
        "password_key",
        algorithm="HS256",
    )

    # AuthResponse(token=..., user=UserOut(...)) viene costruito automaticamente
    return {"token": token, "user": user_db}


# ---------- UTENTE CORRENTE ----------

@router.get("/", response_model=UserOut)
def current_user_data(
    db: Session = Depends(get_db),
    user_dict: dict = Depends(auth_middleware),
):
    user = (
        db.query(User)
        .filter(User.id == user_dict["uid"])
        .options(
            # pre-carica le favorite_songs per popolare UserOut.favorite_songs
            joinedload(User.favorite_songs),
        )
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found!",
        )

    return user


# ---------- LISTA TUTTI GLI UTENTI (eventuale endpoint admin) ----------

@router.get("/all", response_model=list[UserOut])
def get_all_users(
    db: Session = Depends(get_db),
):
    users = (
        db.query(User)
        .options(joinedload(User.favorite_songs))
        .all()
    )

    if not users:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No users found.",
        )

    return users
