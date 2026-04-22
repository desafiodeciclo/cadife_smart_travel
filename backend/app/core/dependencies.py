"""
Backward-compatibility shim for app.core.dependencies
======================================================
Re-exports from the new infrastructure/security location.
"""
from app.infrastructure.security.dependencies import (  # noqa: F401
    bearer_scheme,
    get_current_user,
    get_db,
)
