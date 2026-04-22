"""
Backward-compatibility shim for app.core.security
==================================================
Re-exports from the new infrastructure/security location.
"""
from app.infrastructure.security.jwt import (  # noqa: F401
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
