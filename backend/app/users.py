from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session
from .identity import current_user, user_json
from .database import get_db
from .models import User
from .websocket import hub
router=APIRouter(prefix='/users',tags=['users'])
@router.get('/me')
def me(user:User=Depends(current_user)):return user_json(user)
@router.get('/search')
def search(q:str='',db:Session=Depends(get_db),user:User=Depends(current_user)):
    term = q.strip().lower()
    users = db.scalars(select(User)).all()
    matches = [x for x in users if x.id != user.id and
               (not term or term in x.username.lower() or term in x.email.lower())]
    return [{**user_json(x), 'is_online': hub.online(x.id)} for x in matches[:20]]
