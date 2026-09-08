"""Encryption and lookup helpers for personally identifiable account data."""

import base64
import hashlib
import hmac
import os

from cryptography.fernet import Fernet


def _key_material() -> bytes:
    configured = os.getenv('DATA_ENCRYPTION_KEY')
    if configured:
        return configured.encode()
    secret = os.getenv('JWT_SECRET', 'local-development-secret-change-before-production')
    return base64.urlsafe_b64encode(hashlib.sha256(secret.encode()).digest())


def encrypt(value: str) -> str:
    return 'enc:' + Fernet(_key_material()).encrypt(value.encode()).decode()


def decrypt(value: str) -> str:
    # Enables a safe one-time migration of existing local databases.
    if not value.startswith('enc:'):
        return value
    return Fernet(_key_material()).decrypt(value[4:].encode()).decode()


def lookup(value: str) -> str:
    """Stable keyed digest used for equality lookups without plaintext."""
    secret = os.getenv('DATA_ENCRYPTION_KEY') or os.getenv(
        'JWT_SECRET', 'local-development-secret-change-before-production')
    return hmac.new(secret.encode(), value.strip().lower().encode(), hashlib.sha256).hexdigest()
