"""
Password Reset Schemas — Presentation Layer
==============================================
Request/response schemas for password reset flow.
"""

from pydantic import BaseModel, Field


class PasswordResetRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=255)


class PasswordResetConfirm(BaseModel):
    token: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)


class PasswordResetResponse(BaseModel):
    message: str
