"""
Backward-compatibility shim for app.core.database
==================================================
Re-exports from the new infrastructure/persistence location.
"""
from app.infrastructure.persistence.database import (  # noqa: F401
    AsyncSessionLocal,
    Base,
    create_tables,
    engine,
)
