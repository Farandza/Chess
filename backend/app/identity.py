import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from .database import get_db
from .models import User

bearer = HTTPBearer()
_algorithm = 'HS256'

def hash_password(password: str) -> str:
    """Hash a password with scrypt; never store the password itself."""
    salt = secrets.token_bytes(16)
    derived = hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1)
    return f'scrypt${salt.hex()}${derived.hex()}'

def verify_password(password: str, stored: str) -> bool:
    try:
        kind, salt_hex, digest_hex = stored.split('$')
        if kind != 'scrypt': return False
        derived = hashlib.scrypt(password.encode(), salt=bytes.fromhex(salt_hex), n=2**14, r=8, p=1)
        return hmac.compare_digest(derived.hex(), digest_hex)
    except (ValueError, TypeError): return False

def create_access_token(user: User) -> str:
    secret = os.getenv('JWT_SECRET', 'development-only-change-me')
    now = datetime.now(timezone.utc)
    return jwt.encode({'sub': str(user.id), 'iat': now, 'exp': now + timedelta(days=7)}, secret, algorithm=_algorithm)

def current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer), db: Session = Depends(get_db)) -> User:
    return user_from_token(credentials.credentials, db)

def user_from_token(token: str, db: Session) -> User:
    try:
        claims = jwt.decode(token, os.getenv('JWT_SECRET', 'development-only-change-me'), algorithms=[_algorithm])
        user_id = int(claims['sub'])
    except (jwt.PyJWTError, KeyError, TypeError, ValueError) as error:
        raise HTTPException(401, 'Invalid or expired access token') from error
    user = db.get(User, user_id)
    if user is None: raise HTTPException(401, 'Account no longer exists')
    return user

def user_json(user: User) -> dict: return {'id': user.id, 'username': user.username, 'email': user.email, 'email_verified': user.email_verified, 'rating': user.rating}
