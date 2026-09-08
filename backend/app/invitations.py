from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from .identity import current_user
from .database import get_db
from .models import Invitation, User
from .models import Game
from .chess import STARTING_FEN
router=APIRouter(prefix='/invitations',tags=['invitations'])
class CreateInvitation(BaseModel):to_user_id:int;minutes:int=10;color:str='random'
@router.post('')
def create(payload:CreateInvitation,db:Session=Depends(get_db),user:User=Depends(current_user)):
    if payload.to_user_id==user.id:raise HTTPException(400,'Cannot invite yourself')
    if payload.minutes not in (5,10,15) or payload.color not in ('random','white','black'): raise HTTPException(400,'Invalid game settings')
    invite=Invitation(from_user_id=user.id,to_user_id=payload.to_user_id,minutes=payload.minutes,color=payload.color);db.add(invite);db.commit();db.refresh(invite);return {'id':invite.id,'status':invite.status}
@router.get('')
def mine(db:Session=Depends(get_db),user:User=Depends(current_user)):
    rows=db.scalars(select(Invitation).where(Invitation.to_user_id==user.id,Invitation.status=='pending')).all()
    return [{'id':i.id,'from_user_id':i.from_user_id,'from_username':db.get(User,i.from_user_id).username,'minutes':i.minutes,'color':i.color} for i in rows]

@router.post('/{invitation_id}/accept')
def accept(invitation_id:int,db:Session=Depends(get_db),user:User=Depends(current_user)):
    invite=db.get(Invitation,invitation_id)
    if not invite or invite.to_user_id != user.id: raise HTTPException(404,'Invitation not found')
    if invite.status == 'accepted':
        game = db.query(Game).filter(((Game.white_id == invite.from_user_id) & (Game.black_id == invite.to_user_id)) | ((Game.white_id == invite.to_user_id) & (Game.black_id == invite.from_user_id))).order_by(Game.created_at.desc()).first()
        if game:
            return {'id':game.id,'white_id':game.white_id,'black_id':game.black_id,'white_username':db.get(User,game.white_id).username,'black_username':db.get(User,game.black_id).username,'fen':game.fen,'moves':game.moves.split() if game.moves else [],'status':game.status,'minutes':game.minutes}
    if invite.status != 'pending': raise HTTPException(404,'Invitation not found')
    invite.status='accepted'
    seconds = invite.minutes * 60
    white_id, black_id = (invite.to_user_id, invite.from_user_id) if invite.color == 'black' else (invite.from_user_id, invite.to_user_id)
    game=Game(white_id=white_id,black_id=black_id,minutes=invite.minutes,fen=STARTING_FEN,white_seconds=seconds,black_seconds=seconds)
    db.add(game);db.commit();db.refresh(game)
    return {'id':game.id,'white_id':game.white_id,'black_id':game.black_id,'white_username':db.get(User,game.white_id).username,'black_username':db.get(User,game.black_id).username,'fen':game.fen,'moves':[],'status':'active','minutes':game.minutes}

@router.post('/{invitation_id}/decline')
def decline(invitation_id:int,db:Session=Depends(get_db),user:User=Depends(current_user)):
    invite=db.get(Invitation,invitation_id)
    if not invite or invite.to_user_id != user.id or invite.status != 'pending': raise HTTPException(404,'Invitation not found')
    invite.status='declined';db.commit();return {'status':'declined'}
