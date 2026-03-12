import uuid
import bcrypt
import jwt
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from models.user import User, UserRole
from models.artist import Artist
from schemas.user_schema import UserCreate, UserLogin
from core.config import settings

class Auth:

    @staticmethod
    def signup(db: Session, user_data: UserCreate):
        # 1. Controllo duplicati
        if db.query(User).filter(User.email == user_data.email).first():
            raise HTTPException(status_code=400, detail="User with the same email already exists!")

        # 2. Hashing e preparazione dati
        hashed_pw = bcrypt.hashpw(user_data.password.encode(), bcrypt.gensalt())
        u_id = str(uuid.uuid4())
        
        # Determiniamo il ruolo in base alla scelta dell'utente
        role = UserRole.ARTIST if user_data.is_artist else UserRole.USER

        try:
            # 3. Creazione User
            new_user = User(
                id=u_id,
                email=user_data.email,
                password=hashed_pw,
                name=user_data.name,
                role=role
            )
            db.add(new_user)

            db.commit()
            db.refresh(new_user)
            return new_user
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def login(db: Session, credentials: UserLogin):
        user_db = db.query(User).filter(User.email == credentials.email).first()
        
        if not user_db or not bcrypt.checkpw(credentials.password.encode(), user_db.password):
            raise HTTPException(status_code=400, detail="Incorrect email or password!")

        token = jwt.encode({"id": user_db.id}, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
        return {"token": token, "user": user_db}

    @staticmethod
    def get_current_user(db: Session, user_id: str):
        user = db.query(User).filter(User.id == user_id).options(
            joinedload(User.favorite_songs),
            joinedload(User.artist_profile)
        ).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found!")
        return user