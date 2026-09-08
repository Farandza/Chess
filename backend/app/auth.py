import re
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .database import get_db
from .identity import create_access_token, current_user, hash_password, user_json, verify_password
from .mailer import send_reset_email, send_verification_email
from .models import User
from .crypto import lookup

router = APIRouter(prefix='/auth', tags=['auth'])

class RegisterPayload(BaseModel):
    username: str
    email: str
    password: str

class LoginPayload(BaseModel):
    email: str
    password: str

class ForgotPasswordPayload(BaseModel):
    email: str

class ResetPasswordPayload(BaseModel):
    token: str
    password: str

def _new_verification_token() -> str: return secrets.token_urlsafe(32)

def _valid_password(password: str) -> bool:
    return (len(password) >= 8 and bool(re.search(r'[a-z]', password)) and
            bool(re.search(r'[A-Z]', password)) and bool(re.search(r'\d', password)) and
            bool(re.search(r'[^A-Za-z0-9]', password)))

def _send_verification(user: User, db: Session) -> None:
    user.verification_token = _new_verification_token()
    db.commit()
    send_verification_email(user.email, user.username, user.verification_token)

@router.post('/register', status_code=201)
def register(payload: RegisterPayload, db: Session = Depends(get_db)):
    username, email = payload.username.strip(), payload.email.strip().lower()
    if not 2 <= len(username) <= 32: raise HTTPException(400, 'Player name must be 2–32 characters.')
    if '@' not in email or len(email) > 255: raise HTTPException(400, 'Enter a valid email address.')
    if not _valid_password(payload.password):
        raise HTTPException(400, 'Password must have 8+ characters including lowercase, uppercase, digit, and special character.')
    user = User(username=username, email=email, password_hash=hash_password(payload.password), verification_token=_new_verification_token())
    db.add(user)
    try:
        db.commit(); db.refresh(user)
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(409, 'That player name or email is already in use.') from error
    send_verification_email(user.email, user.username, user.verification_token)
    return {'access_token': create_access_token(user), 'user': user_json(user)}

@router.post('/login')
def login(payload: LoginPayload, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email_lookup == lookup(payload.email)).first()
    if user is None or not verify_password(payload.password, user.password_hash): raise HTTPException(401, 'Incorrect email or password.')
    return {'access_token': create_access_token(user), 'user': user_json(user)}

@router.get('/verify-email')
def verify_email(token: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.verification_token == token).first()
    if user is None: raise HTTPException(400, 'This verification link is invalid or has already been used.')
    user.email_verified = True; user.verification_token = None; db.commit()
    return {'message': 'Email verified. Return to the Chess app and sign in.'}

@router.post('/resend-verification')
def resend_verification(user: User = Depends(current_user), db: Session = Depends(get_db)):
    if user.email_verified: return {'message': 'Email is already verified.'}
    _send_verification(user, db)
    return {'message': 'Verification email sent.'}

@router.post('/forgot-password')
def forgot_password(payload: ForgotPasswordPayload, db: Session = Depends(get_db)):
    # Always return success so the endpoint cannot be used to enumerate accounts.
    user = db.query(User).filter(User.email_lookup == lookup(payload.email)).first()
    if user:
        user.reset_token = secrets.token_urlsafe(32)
        user.reset_token_expires_at = datetime.utcnow() + timedelta(minutes=30)
        db.commit()
        send_reset_email(user.email, user.username, user.reset_token)
    return {'message': 'If that account exists, a reset email has been sent.'}

@router.post('/reset-password')
def reset_password(payload: ResetPasswordPayload, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.reset_token == payload.token).first()
    if user is None or user.reset_token_expires_at is None or user.reset_token_expires_at < datetime.utcnow():
        raise HTTPException(400, 'This password-reset link is invalid or expired.')
    if not _valid_password(payload.password):
        raise HTTPException(400, 'Password must have 8+ characters including lowercase, uppercase, digit, and special character.')
    user.password_hash = hash_password(payload.password)
    user.reset_token = None
    user.reset_token_expires_at = None
    db.commit()
    return {'message': 'Password updated. You can now sign in.'}

@router.get('/reset-password', response_class=HTMLResponse)
def reset_password_page(token: str):
    return f'''<!doctype html><html><body style="font-family:sans-serif;max-width:420px;margin:48px auto">
<h1>Reset password</h1><p id="message">Choose a strong new password.</p>
<input id="password" type="password" placeholder="New password" style="width:100%;padding:10px"><br><br>
<button onclick="resetPassword()">Update password</button>
<script>async function resetPassword() {{ const r=await fetch('/auth/reset-password',{{method:'POST',headers:{{'Content-Type':'application/json'}},body:JSON.stringify({{token:{token!r},password:password.value}})}}); const d=await r.json(); message.textContent=d.message||d.detail; }}</script>
</body></html>'''
