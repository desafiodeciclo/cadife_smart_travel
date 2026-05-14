"""
PasswordResetToken ORM — Domain/Models Layer (canonical shim)
===========================================================
Shim for backward compatibility. Delegates to persistence layer.
"""

from app.infrastructure.persistence.models.password_reset_token_model import PasswordResetToken  # noqa: F401
