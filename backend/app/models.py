from datetime import datetime
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .crypto import decrypt, encrypt, lookup
class User(Base):
    __tablename__='users'
    id: Mapped[int]=mapped_column(primary_key=True)
    _username: Mapped[str]=mapped_column('username', String(512), unique=True, index=True)
    _email: Mapped[str]=mapped_column('email', String(512), unique=True, index=True)
    username_lookup: Mapped[str]=mapped_column(String(64), unique=True, index=True)
    email_lookup: Mapped[str]=mapped_column(String(64), unique=True, index=True)
    password_hash: Mapped[str]=mapped_column(String(256))
    email_verified: Mapped[bool]=mapped_column(Boolean, default=False)
    verification_token: Mapped[str | None]=mapped_column(String(128), unique=True, nullable=True)
    reset_token: Mapped[str | None]=mapped_column(String(128), unique=True, nullable=True)
    reset_token_expires_at: Mapped[datetime | None]=mapped_column(DateTime, nullable=True)
    rating: Mapped[int]=mapped_column(Integer,default=1200)

    @property
    def username(self) -> str:
        return decrypt(self._username)

    @username.setter
    def username(self, value: str) -> None:
        self._username = encrypt(value)
        self.username_lookup = lookup(value)

    @property
    def email(self) -> str:
        return decrypt(self._email)

    @email.setter
    def email(self, value: str) -> None:
        self._email = encrypt(value)
        self.email_lookup = lookup(value)
class Invitation(Base):
    __tablename__='invitations'
    id: Mapped[int]=mapped_column(primary_key=True); from_user_id: Mapped[int]=mapped_column(ForeignKey('users.id')); to_user_id: Mapped[int]=mapped_column(ForeignKey('users.id')); minutes: Mapped[int]=mapped_column(default=10); color: Mapped[str]=mapped_column(String(8),default='random'); status: Mapped[str]=mapped_column(String(16),default='pending'); created_at: Mapped[datetime]=mapped_column(DateTime,default=datetime.utcnow)
class Game(Base):
    __tablename__='games'
    id: Mapped[int]=mapped_column(primary_key=True); white_id: Mapped[int]=mapped_column(ForeignKey('users.id')); black_id: Mapped[int]=mapped_column(ForeignKey('users.id')); fen: Mapped[str]=mapped_column(Text); moves: Mapped[str]=mapped_column(Text,default=''); status: Mapped[str]=mapped_column(String(16),default='active'); minutes: Mapped[int]=mapped_column(default=10); created_at: Mapped[datetime]=mapped_column(DateTime,default=datetime.utcnow)
    turn: Mapped[str]=mapped_column(String(5), default='white')
    white_seconds: Mapped[int]=mapped_column(Integer, default=600)
    black_seconds: Mapped[int]=mapped_column(Integer, default=600)
    last_clock_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)
    result: Mapped[str | None]=mapped_column(String(32), nullable=True)
    restart_requested_by: Mapped[int | None]=mapped_column(ForeignKey('users.id'), nullable=True)
    restart_expires_at: Mapped[datetime | None]=mapped_column(DateTime, nullable=True)
    paused_at: Mapped[datetime | None]=mapped_column(DateTime, nullable=True)
