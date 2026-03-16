from sqlite3 import IntegrityError
import uuid
import bcrypt
import jwt
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from models import user
from models.user import User, UserRole
from models.artist import Artist
from schemas.user_schema import UserCreate, UserLogin, UserPasswordChange, UserUpdate
from core.config import settings

class Auth:


    @staticmethod
    def _get_user_or_404(db: Session, user_id: str) -> User:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user

    @staticmethod
    def _assert_self_or_admin(requester: User, target_user_id: str) -> None:
        is_admin = requester.role == UserRole.ADMIN
        is_self = requester.id == target_user_id

        if not (is_admin or is_self):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to perform this action",
            )


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
                role=role,
                image_url=user_data.image_url
            )
            db.add(new_user)

            db.commit()
            db.refresh(new_user)
            return new_user
        
        except IntegrityError:
            db.rollback()
            raise HTTPException(
                status_code=400,
                detail="User with the same email already exists!",
            )
        
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
    
    @staticmethod
    def update_user_profile(db: Session, user_id: str, update_data: UserUpdate):

        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        update_dict = update_data.model_dump(exclude_unset=True)

        for field, value in update_dict.items():
            setattr(user, field, value)

        db.commit()
        db.refresh(user)

        return user    

    @staticmethod
    def delete_user(db: Session, requester_id: str, target_user_id: str) -> None:
        requester = Auth._get_user_or_404(db, requester_id)
        target_user = Auth._get_user_or_404(db, target_user_id)

        Auth._assert_self_or_admin(requester, target_user_id)

        try:
            db.delete(target_user)
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Deletion failed: {str(e)}")

    @staticmethod
    def change_user_password(
        db: Session,
        requester_id: str,
        target_user_id: str,
        payload: UserPasswordChange,
    ) -> None:
        requester = Auth._get_user_or_404(db, requester_id)
        target_user = Auth._get_user_or_404(db, target_user_id)

        Auth._assert_self_or_admin(requester, target_user_id)

        is_admin = requester.role == UserRole.ADMIN
        is_self = requester.id == target_user_id

        # Se l'utente cambia la propria password e NON è admin,
        # deve fornire la password attuale.
        if is_self and not is_admin:
            if not payload.current_password:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Current password is required",
                )

            if not bcrypt.checkpw(
                payload.current_password.encode(),
                target_user.password,
            ):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Current password is incorrect",
                )

        # Evita password identica a quella attuale
        if bcrypt.checkpw(payload.new_password.encode(), target_user.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be different from the current password",
            )

        try:
            target_user.password = bcrypt.hashpw(
                payload.new_password.encode(),
                bcrypt.gensalt(),
            )
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Password change failed: {str(e)}",
            )