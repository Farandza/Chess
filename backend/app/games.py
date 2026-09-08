from datetime import datetime, timedelta

import chess
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .database import get_db
from .identity import current_user
from .models import Game, User
from .websocket import hub

router = APIRouter(prefix='/games', tags=['games'])

class CreateGame(BaseModel): opponent_id: int; minutes: int = 10; color: str = 'random'
class MovePayload(BaseModel): move: str

def _apply_clock(game: Game) -> None:
    if game.status == 'restart_pending' and game.restart_expires_at and game.restart_expires_at <= datetime.utcnow():
        game.status = 'active'; game.restart_requested_by = None; game.restart_expires_at = None; game.last_clock_at = datetime.utcnow()
    if game.status != 'active' or game.last_clock_at is None: return
    elapsed = max(0, int((datetime.utcnow() - game.last_clock_at).total_seconds()))
    if game.turn == 'white': game.white_seconds = max(0, game.white_seconds - elapsed)
    else: game.black_seconds = max(0, game.black_seconds - elapsed)
    game.last_clock_at = datetime.utcnow()
    if game.white_seconds == 0: game.status, game.result = 'finished', 'black_timeout'
    if game.black_seconds == 0: game.status, game.result = 'finished', 'white_timeout'

def _finish(board: chess.Board, game: Game) -> None:
    if board.is_checkmate(): game.status, game.result = 'finished', ('white_checkmate' if board.turn == chess.BLACK else 'black_checkmate')
    elif board.is_stalemate() or board.is_insufficient_material() or board.can_claim_threefold_repetition(): game.status, game.result = 'finished', 'draw'

def serialize(game: Game, db: Session | None = None) -> dict:
    data = {'id': game.id, 'white_id': game.white_id, 'black_id': game.black_id, 'fen': game.fen, 'moves': game.moves.split() if game.moves else [], 'status': game.status, 'minutes': game.minutes, 'turn': game.turn, 'white_seconds': game.white_seconds, 'black_seconds': game.black_seconds, 'result': game.result, 'restart_expires_at': game.restart_expires_at.isoformat() if game.restart_expires_at else None, 'paused_at': game.paused_at.isoformat() if game.paused_at else None}
    if db:
        data['white_username'] = db.get(User, game.white_id).username
        data['black_username'] = db.get(User, game.black_id).username
    return data

async def _broadcast(game: Game, db: Session): await hub.broadcast(game.id, {'type': 'game_state', 'game': serialize(game, db)})

async def tick_game(game: Game, db: Session) -> None:
    """Advance clocks and enforce the two-minute reconnect grace period."""
    white_online, black_online = hub.online(game.white_id), hub.online(game.black_id)
    changed = False
    if game.status == 'active' and (not white_online or not black_online):
        game.status, game.paused_at = 'paused', datetime.utcnow(); changed = True
    elif game.status == 'paused':
        if white_online and black_online:
            game.status, game.paused_at, game.last_clock_at = 'active', None, datetime.utcnow(); changed = True
        elif game.paused_at and datetime.utcnow() - game.paused_at >= timedelta(minutes=2):
            game.status = 'finished'; game.result = 'black_disconnect' if not white_online else 'white_disconnect'; changed = True
    elif game.status in ('active', 'restart_pending'):
        before = (game.white_seconds, game.black_seconds, game.status, game.result)
        _apply_clock(game)
        changed = before != (game.white_seconds, game.black_seconds, game.status, game.result)
    if changed:
        db.commit(); await _broadcast(game, db)

@router.post('')
def create(payload: CreateGame, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if payload.minutes not in (5, 10, 15): raise HTTPException(400, 'Choose 5, 10, or 15 minutes.')
    if payload.opponent_id == user.id or not db.get(User, payload.opponent_id): raise HTTPException(400, 'Invalid opponent.')
    white, black = (user.id, payload.opponent_id) if payload.color != 'black' else (payload.opponent_id, user.id)
    seconds = payload.minutes * 60
    game = Game(white_id=white, black_id=black, minutes=payload.minutes, fen=chess.STARTING_FEN, white_seconds=seconds, black_seconds=seconds)
    db.add(game); db.commit(); db.refresh(game); return serialize(game, db)

@router.get('/{game_id}')
async def get_game(game_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    game = db.get(Game, game_id)
    if not game or user.id not in (game.white_id, game.black_id): raise HTTPException(404, 'Game not found')
    _apply_clock(game); db.commit(); await _broadcast(game, db); return serialize(game, db)

@router.get('')
def list_games(db: Session = Depends(get_db), user: User = Depends(current_user)):
    games = db.query(Game).filter((Game.white_id == user.id) | (Game.black_id == user.id)).order_by(Game.created_at.desc()).all()
    rows = []
    for game in games:
        item = serialize(game, db)
        rows.append(item)
    return rows

@router.post('/{game_id}/moves')
async def move(game_id: int, payload: MovePayload, db: Session = Depends(get_db), user: User = Depends(current_user)):
    game = db.get(Game, game_id)
    if not game or user.id not in (game.white_id, game.black_id): raise HTTPException(404, 'Game not found')
    _apply_clock(game)
    if game.status != 'active': raise HTTPException(400, 'Game is not active')
    expected = game.white_id if game.turn == 'white' else game.black_id
    if user.id != expected: raise HTTPException(400, 'It is not your turn')
    try: move = chess.Move.from_uci(payload.move)
    except ValueError as error: raise HTTPException(400, 'Invalid move') from error
    board = chess.Board(game.fen)
    if move not in board.legal_moves: raise HTTPException(400, 'Illegal move')
    board.push(move); game.fen = board.fen(); game.moves = f'{game.moves} {payload.move}'.strip(); game.turn = 'black' if game.turn == 'white' else 'white'; game.last_clock_at = datetime.utcnow(); _finish(board, game)
    db.commit(); await _broadcast(game, db); return serialize(game, db)

@router.post('/{game_id}/restart')
async def restart(game_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    game = db.get(Game, game_id)
    if not game or user.id not in (game.white_id, game.black_id): raise HTTPException(404, 'Game not found')
    if game.restart_requested_by and game.restart_requested_by != user.id and game.restart_expires_at and game.restart_expires_at > datetime.utcnow():
        seconds = game.minutes * 60; game.fen = chess.STARTING_FEN; game.moves = ''; game.turn = 'white'; game.white_seconds = seconds; game.black_seconds = seconds; game.status = 'active'; game.result = None; game.restart_requested_by = None; game.restart_expires_at = None; game.last_clock_at = datetime.utcnow()
    else:
        game.restart_requested_by = user.id; game.restart_expires_at = datetime.utcnow() + timedelta(seconds=30); game.status = 'restart_pending'
    db.commit(); await _broadcast(game, db); return serialize(game, db)

@router.post('/{game_id}/quit')
async def quit_game(game_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    game = db.get(Game, game_id)
    if not game or user.id not in (game.white_id, game.black_id): raise HTTPException(404, 'Game not found')
    if game.status == 'finished': raise HTTPException(400, 'Game is already finished')
    game.status = 'finished'
    game.result = 'black_resigned' if user.id == game.white_id else 'white_resigned'
    db.commit(); await _broadcast(game, db); return serialize(game, db)
