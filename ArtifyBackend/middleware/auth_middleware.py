import jwt
from fastapi import Depends, HTTPException, Header, status
from sqlalchemy.orm import Session

from core.config import settings
from database import get_db
from models.enums import UserRole          # FIX: da enums.py
from models.user import User


# ------------------------------------------------------------------ #
#  Autenticazione: chi sei?                                          #
# ------------------------------------------------------------------ #

def auth_middleware(
    # FIX: default=None rende il parametro opzionale a livello FastAPI,
    # così il check `if not x_auth_token` diventa effettivo e restituisce
    # 401 invece del 422 che FastAPI generava prima con Header() obbligatorio.
    x_auth_token: str | None = Header(default=None),
) -> dict:
    if not x_auth_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No auth token — access denied",
        )

    try:
        verified_token = jwt.decode(
            x_auth_token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )

        # FIX: validazione esplicita del campo id nel payload.
        # jwt.decode non restituisce mai None — il check `if not verified_token`
        # era dead code ed è stato rimosso.
        uid = verified_token.get("id")
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
            )

        # FIX: role codificato nel token per evitare una query DB ad ogni
        # request in require_role. Aggiunto al payload in auth_service._encode_token.
        role = verified_token.get("role")

        return {"uid": uid, "role": role, "token": x_auth_token}

    # FIX: ExpiredSignatureError separato per dare al client Flutter
    # un segnale chiaro: token scaduto → vai al login, non token manomesso.
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired — please log in again",
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token — authorization failed",
        )


# ------------------------------------------------------------------ #
#  Autorizzazione: cosa puoi fare?                                   #
# ------------------------------------------------------------------ #

def require_role(allowed_roles: list[UserRole]):
    """
    Dependency FastAPI che verifica il ruolo dell'utente.

    Strategia a due livelli:
    1. Il ruolo viene prima controllato direttamente dal token JWT
       (zero query DB) — sufficiente per la maggior parte degli endpoint.
    2. Se l'endpoint ha bisogno dell'oggetto User completo (es. per leggere
       artist_id o aggiornare dati), la query DB viene fatta qui e l'oggetto
       User restituito è disponibile come dipendenza nella route.
    """
    def role_checker(
        auth_data: dict = Depends(auth_middleware),
        db: Session = Depends(get_db),
    ) -> User:
        # FIX: verifica ruolo dal token prima di toccare il DB.
        token_role = auth_data.get("role")
        if token_role:
            try:
                if UserRole(token_role) not in allowed_roles:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Access denied — insufficient permissions",
                    )
            except ValueError:
                # Ruolo nel token non riconosciuto — forza verifica DB.
                pass

        # Query DB per ottenere l'oggetto User completo e verificare
        # il ruolo aggiornato (nel caso sia cambiato dopo l'emissione del token).
        user = db.query(User).filter(User.id == auth_data["uid"]).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied — insufficient permissions",
            )

        # FIX: rimosso `...` (Ellipsis) inutile prima del return.
        return user

    return role_checker