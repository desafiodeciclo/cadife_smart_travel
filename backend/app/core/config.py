"""
Backward-compatibility shim for app.core.config
================================================
Re-exports from the canonical infrastructure/config location.
All services should continue importing from here — no changes required.
"""
from app.infrastructure.config.settings import Settings, get_settings  # noqa: F401
