"""
Backward-compatibility shim for app.core.config
================================================
Re-exports from the canonical infrastructure/config location.
All services should continue importing from here — no changes required.
"""

from app.infrastructure.config.settings import Settings as Settings
from app.infrastructure.config.settings import get_settings as get_settings

__all__ = ["Settings", "get_settings"]
