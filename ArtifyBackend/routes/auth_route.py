from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session, joinedload
from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.user import User, UserRole
from schemas.user_schema import UserCreate, UserLogin, UserOut
from services.auth_service import Auth
from pydantic import BaseModel

router = APIRouter()

class AuthResponse(BaseModel):
    token: str
    user: UserOut

@router.post("/signup", status_code=status.HTTP_201_CREATED, response_model=UserOut)
def signup_user(user: UserCreate, db: Session = Depends(get_db)):
    return Auth.signup(db, user)

@router.post("/login", response_model=AuthResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    return Auth.login(db, user)

@router.get("/", response_model=UserOut)
def current_user_data(db: Session = Depends(get_db), user_dict: dict = Depends(auth_middleware)):
    return Auth.get_current_user(db, user_dict["uid"])

@router.get("/all", response_model=list[UserOut])
def get_all_users(db: Session = Depends(get_db),
                  current_admin: User = Depends(require_role([UserRole.ADMIN]))
                  ):
    # Anche questo andrebbe nel service, ma per brevità lo lasciamo o lo spostiamo
    return db.query(User).options(joinedload(User.favorite_songs)).all()