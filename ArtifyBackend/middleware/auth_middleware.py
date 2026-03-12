from fastapi import Depends, HTTPException, Header
import jwt
from sqlalchemy.orm import Session

from database import get_db
from models.user import User, UserRole

from core.config import settings

def auth_middleware(x_auth_token = Header()):
    try:
        # get the user token from the headers
        if not x_auth_token:
            raise HTTPException(401, 'No auth token, access denied!')
        # decode the token
        verified_token = jwt.decode(x_auth_token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])

        if not verified_token:
            raise HTTPException(401, 'Token verification failed, authorization denied!')
        # get the id from the token
        uid = verified_token.get('id')
        return {'uid': uid, 'token': x_auth_token}
        # postgres database get the user info
    except jwt.PyJWTError:
        raise HTTPException(401, 'Token is not valid, authorization failed.')

# 2. AUTORIZZAZIONE: Cosa puoi fare? (IL BUTTAFUORI)
def require_role(allowed_roles: list[UserRole]):
    """
    Questo è un "Dependency Injector" avanzato di FastAPI.
    Controlla se l'utente loggato ha uno dei ruoli permessi.
    """
    def role_checker(
        auth_data: dict = Depends(auth_middleware),
        db: Session = Depends(get_db)
    ):
        # Cerchiamo l'utente nel DB usando l'ID preso dal token
        user = db.query(User).filter(User.id == auth_data['uid']).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found!")
            
        # Il momento della verità: Il ruolo dell'utente è nella lista VIP?
        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=403, # 403 Forbidden: So chi sei, ma non puoi entrare.
                detail="Access denied: You do not have the required permissions."
            )
            
        # Ritorniamo l'oggetto User! Questo ci sarà utilissimo nelle rotte.
        ...
        return user 

    return role_checker