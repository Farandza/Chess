import asyncio
from contextlib import suppress
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from .users import router as users_router
from .auth import router as auth_router
from .invitations import router as invitations_router
from .games import router as games_router
from .websocket import hub
from .database import SessionLocal
from .identity import user_from_token
from .models import Game
from .games import tick_game
from .crypto import decrypt, encrypt, lookup
Base.metadata.create_all(bind=engine)

def _migrate_sqlite() -> None:
    """Add fields introduced after the first local database was created."""
    if not str(engine.url).startswith('sqlite'):
        return
    with engine.begin() as connection:
        columns = {row[1] for row in connection.exec_driver_sql('PRAGMA table_info(users)')}
        if 'username_lookup' not in columns:
            connection.exec_driver_sql('ALTER TABLE users ADD COLUMN username_lookup VARCHAR(64)')
        if 'email_lookup' not in columns:
            connection.exec_driver_sql('ALTER TABLE users ADD COLUMN email_lookup VARCHAR(64)')
        if 'reset_token' not in columns:
            connection.exec_driver_sql('ALTER TABLE users ADD COLUMN reset_token VARCHAR(128)')
        if 'reset_token_expires_at' not in columns:
            connection.exec_driver_sql('ALTER TABLE users ADD COLUMN reset_token_expires_at DATETIME')
        # Encrypt old plaintext account values and create irreversible lookup
        # keys used by login, uniqueness checks, and player search.
        rows = connection.exec_driver_sql(
            'SELECT id, username, email FROM users').mappings().all()
        for row in rows:
            username = row['username']
            email = row['email']
            plain_username = decrypt(username)
            plain_email = decrypt(email)
            connection.exec_driver_sql(
                'UPDATE users SET username = :username, email = :email, '
                'username_lookup = :username_lookup, email_lookup = :email_lookup '
                'WHERE id = :id',
                {
                    'id': row['id'],
                    'username': username if username.startswith('enc:') else encrypt(plain_username),
                    'email': email if email.startswith('enc:') else encrypt(plain_email),
                    'username_lookup': lookup(plain_username),
                    'email_lookup': lookup(plain_email),
                })
        connection.exec_driver_sql(
            'CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username_lookup ON users (username_lookup)')
        connection.exec_driver_sql(
            'CREATE UNIQUE INDEX IF NOT EXISTS ix_users_email_lookup ON users (email_lookup)')
        game_columns = {row[1] for row in connection.exec_driver_sql('PRAGMA table_info(games)')}
        additions = {'turn': "VARCHAR(5) DEFAULT 'white'", 'white_seconds': 'INTEGER DEFAULT 600', 'black_seconds': 'INTEGER DEFAULT 600', 'last_clock_at': 'DATETIME', 'result': 'VARCHAR(32)', 'restart_requested_by': 'INTEGER', 'restart_expires_at': 'DATETIME', 'paused_at': 'DATETIME'}
        for column, sql_type in additions.items():
            if column not in game_columns:
                connection.exec_driver_sql(f'ALTER TABLE games ADD COLUMN {column} {sql_type}')
        invitation_columns = {row[1] for row in connection.exec_driver_sql('PRAGMA table_info(invitations)')}
        if 'color' not in invitation_columns:
            connection.exec_driver_sql("ALTER TABLE invitations ADD COLUMN color VARCHAR(8) DEFAULT 'random'")

_migrate_sqlite()
app = FastAPI(title='Chess Multiplayer API')
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_credentials=True, allow_methods=['*'], allow_headers=['*'])
app.include_router(auth_router); app.include_router(users_router); app.include_router(invitations_router); app.include_router(games_router)
_game_tick_task = None

async def _game_tick_loop():
    while True:
        db = SessionLocal()
        try:
            for game in db.query(Game).filter(Game.status.in_(['active', 'paused', 'restart_pending'])).all():
                await tick_game(game, db)
        finally:
            db.close()
        await asyncio.sleep(1)

@app.on_event('startup')
async def start_game_tick():
    global _game_tick_task
    _game_tick_task = asyncio.create_task(_game_tick_loop())

@app.on_event('shutdown')
async def stop_game_tick():
    if _game_tick_task:
        _game_tick_task.cancel()
        with suppress(asyncio.CancelledError): await _game_tick_task
@app.get('/health')
def health(): return {'status': 'ok'}
@app.websocket('/ws/games/{game_id}')
async def game_socket(websocket: WebSocket, game_id: int, token: str):
    if not token: await websocket.close(code=1008); return
    db = SessionLocal()
    try: user = user_from_token(token, db)
    except Exception: await websocket.close(code=1008); db.close(); return
    game = db.get(Game, game_id)
    if not game or user.id not in (game.white_id, game.black_id): await websocket.close(code=1008); db.close(); return
    await hub.connect(game_id, user.id, websocket)
    try:
        while True: await websocket.receive_text()
    except WebSocketDisconnect: await hub.disconnect(game_id, websocket)
    finally: db.close()

@app.websocket('/ws/presence')
async def presence_socket(websocket: WebSocket, token: str):
    if not token: await websocket.close(code=1008); return
    db = SessionLocal()
    try: user = user_from_token(token, db)
    except Exception: await websocket.close(code=1008); db.close(); return
    await hub.connect_presence(user.id, websocket)
    try:
        while True: await websocket.receive_text()
    except WebSocketDisconnect: await hub.disconnect_presence(websocket)
    finally: db.close()
