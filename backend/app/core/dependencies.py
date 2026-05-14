"""
Backward-compatibility shim for app.core.dependencies
======================================================
Re-exports from the new infrastructure/security location.
"""

from app.infrastructure.persistence.database import AsyncSessionLocal  # noqa: F401
from app.infrastructure.security.dependencies import (  # noqa: F401
    bearer_scheme,
    get_current_user,
    get_db,
)


def get_db_session():
    """Return an async context manager yielding a fresh, isolated DB session.

    Use this outside of FastAPI request scope (Kafka consumers, background workers).
    Usage: async with get_db_session() as db: ...
    """
    return AsyncSessionLocal()
