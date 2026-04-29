"""
Firebase Adapter — Infrastructure/Adapters Layer
=================================================
Initializes Firebase Admin SDK for FCM push notifications.
Implements spec.md §3.3 (FCM) and §8.1 (notification < 2s).
"""
from pathlib import Path

import structlog

logger = structlog.get_logger()

_firebase_initialized = False


def init_firebase() -> None:
    """
    Initialize Firebase Admin SDK.
    Called once during app startup (lifespan).
    Gracefully skips if credentials file is missing (allows local dev without Firebase).
    """
    global _firebase_initialized

    if _firebase_initialized:
        return

    from app.infrastructure.config.settings import get_settings
    settings = get_settings()

    credentials_path = Path(settings.FIREBASE_CREDENTIALS)

    if not credentials_path.exists():
        logger.warning(
            "firebase_credentials_not_found",
            path=str(credentials_path),
            note="FCM notifications will be disabled. Add firebase_credentials.json to enable.",
        )
        return

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(str(credentials_path))
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("firebase_initialized", credentials_path=str(credentials_path))
    except Exception as exc:
        logger.error("firebase_init_failed", error=str(exc))


def is_firebase_ready() -> bool:
    """Returns True if Firebase was successfully initialized."""
    return _firebase_initialized
