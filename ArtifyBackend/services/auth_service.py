from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from models.enums import UserRole
from models.user import User
from schemas.user_schema import UserCreate, UserLogin, UserPasswordChange, UserUpdate
from core.config import settings


class Auth:

    # ------------------------------------------------------------------ #
    #  Helper privati                                                      #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _get_user_or_404(db: Session, user_id: str) -> User:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    @staticmethod
    def _assert_self_or_admin(requester: User, target_user_id: str) -> None:
        if requester.id != target_user_id and requester.role != UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to perform this action",
            )

    @staticmethod
    def _encode_token(user_id: str, role: UserRole) -> str:
        """
        Genera un JWT firmato con exp, iat e role.
        - exp: scadenza configurabile via settings.JWT_EXPIRE_DAYS.
        - role: codificato nel token per il fast-path del middleware
          (evita una query DB ad ogni request per la sola verifica del ruolo).
        """
        now = datetime.now(tz=timezone.utc)
        payload = {
            "id": user_id,
            "role": role.value,
            "iat": now,
            "exp": now + timedelta(days=settings.JWT_EXPIRE_DAYS),
        }
        return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    # ------------------------------------------------------------------ #
    #  Auth                                                               #
    # ------------------------------------------------------------------ #

    @staticmethod
    def signup(db: Session, user_data: UserCreate) -> User:
        if db.query(User).filter(User.email == user_data.email).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )

        hashed_pw = bcrypt.hashpw(user_data.password.encode(), bcrypt.gensalt())
        role = UserRole.ARTIST if user_data.is_artist else UserRole.USER

        new_user = User(
            email=user_data.email,
            password=hashed_pw,
            name=user_data.name,
            role=role,
            image_url=str(user_data.image_url) if user_data.image_url else None,
        )

        try:
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            return new_user

        except IntegrityError:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )

        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Signup failed: {str(e)}",
            )

    @staticmethod
    def login(db: Session, credentials: UserLogin) -> dict:
        user_db = db.query(User).filter(User.email == credentials.email).first()

        password_to_check = user_db.password if user_db else bcrypt.hashpw(b"dummy", bcrypt.gensalt())
        password_matches = bcrypt.checkpw(credentials.password.encode(), password_to_check)

        if not user_db or not password_matches:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
            )

        # Passa il ruolo a _encode_token — il middleware lo leggerà
        # dal token per il fast-path senza query DB.
        token = Auth._encode_token(user_db.id, user_db.role)
        return {"token": token, "user": user_db}

    # ------------------------------------------------------------------ #
    #  Lettura utente                                                     #
    # ------------------------------------------------------------------ #

    @staticmethod
    def get_current_user(db: Session, user_id: str) -> User:
        user = (
            db.query(User)
            .filter(User.id == user_id)
            .options(joinedload(User.artist_profile))
            .first()
        )
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    # ------------------------------------------------------------------ #
    #  Aggiornamento profilo                                              #
    # ------------------------------------------------------------------ #

    @staticmethod
    def update_user_profile(
        db: Session,
        requester_id: str,
        target_user_id: str,
        update_data: UserUpdate,
    ) -> User:
        requester = Auth._get_user_or_404(db, requester_id)
        target_user = Auth._get_user_or_404(db, target_user_id)
        Auth._assert_self_or_admin(requester, target_user_id)

        update_dict = update_data.model_dump(exclude_unset=True)

        if "image_url" in update_dict and update_dict["image_url"] is not None:
            update_dict["image_url"] = str(update_dict["image_url"])

        for field, value in update_dict.items():
            setattr(target_user, field, value)

        try:
            db.commit()
            db.refresh(target_user)
            return target_user
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Update failed: {str(e)}",
            )

    # ------------------------------------------------------------------ #
    #  Eliminazione utente                                               #
    # ------------------------------------------------------------------ #

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
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Deletion failed: {str(e)}",
            )

    # ------------------------------------------------------------------ #
    #  Cambio password                                                    #
    # ------------------------------------------------------------------ #

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

        is_self_non_admin = (requester.id == target_user_id) and (requester.role != UserRole.ADMIN)

        if is_self_non_admin:
            if not bcrypt.checkpw(payload.current_password.encode(), target_user.password):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Current password is incorrect",
                )

        if bcrypt.checkpw(payload.new_password.encode(), target_user.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be different from the current one",
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
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Password change failed: {str(e)}",
            )