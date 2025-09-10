from fastapi import HTTPException
from fastapi.params import Header
import jwt


def auth_middleware(x_auth_token=Header()):

    try:
        if not x_auth_token:
            raise HTTPException(401, 'Authentication token is required!')

        verified_token = jwt.decode(x_auth_token, 'password_key', algorithms=['HS256'])
        if not verified_token:
            raise HTTPException(401, 'Token verification failed!')

        uid = verified_token.get('id')
        return {'uid': uid, 'token': x_auth_token}
    except jwt.PyJWTError:
        raise HTTPException(401, 'Invalid authentication token!')