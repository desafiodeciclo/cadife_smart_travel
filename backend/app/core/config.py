"""
Backward-compatibility shim for app.core.config
================================================
Re-exports from the new infrastructure/config location.
Existing files importing from app.core.config continue to work
while the migration to the new architecture is in progress.
"""
from app.infrastructure.config.settings import Settings, get_settings  # noqa: F401
