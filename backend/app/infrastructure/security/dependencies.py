"""
Dependency Injection — Infrastructure/Security Layer
=====================================================
FastAPI dependency providers for DB session and authenticated user.
"""

from typing import TYPE_CHECKING, AsyncGenerator, Optional

if TYPE_CHECKING:
    from app.models.user import User

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.database import AsyncSessionLocal
from app.infrastructure.security.jwt import decode_token
from app.infrastructure.persistence.models.revoked_token_model import RevokedTokenModel
from sqlalchemy import select
from datetime import datetime, timezone

bearer_scheme = HTTPBearer()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yields an async DB session, auto-closing on exit."""
    async with AsyncSessionLocal() as session:
        yield session


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> "User":
    """Validate Bearer JWT and return the authenticated user."""
    try:
        payload = decode_token(credentials.credentials)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido"
        )
        
    is_revoked = await db.scalar(select(RevokedTokenModel).where(RevokedTokenModel.token == credentials.credentials))
    if is_revoked:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revogado"
        )

    from app.services.user_service import (
        get_user_by_id,
    )  # keep lazy import to avoid circular

    user = await get_user_by_id(db, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuário não encontrado"
        )
        
    iat_timestamp = payload.get("iat")
    if iat_timestamp and user.global_logout_at:
        iat_dt = datetime.fromtimestamp(iat_timestamp, tz=timezone.utc)
        if iat_dt < user.global_logout_at:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Sessão expirada (logout global)"
            )
            
    return user


_optional_bearer = HTTPBearer(auto_error=False)


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_optional_bearer),
    db: AsyncSession = Depends(get_db),
) -> "Optional[User]":
    """Return the authenticated user if a valid Bearer token is present, else None."""
    if not credentials:
        return None
    try:
        payload = decode_token(credentials.credentials)
    except ValueError:
        return None

    if payload.get("type") != "access":
        return None
        
    is_revoked = await db.scalar(select(RevokedTokenModel).where(RevokedTokenModel.token == credentials.credentials))
    if is_revoked:
        return None

    from app.services.user_service import get_user_by_id

    user = await get_user_by_id(db, payload["sub"])
    if not user or not user.is_active:
        return None
        
    iat_timestamp = payload.get("iat")
    if iat_timestamp and user.global_logout_at:
        iat_dt = datetime.fromtimestamp(iat_timestamp, tz=timezone.utc)
        if iat_dt < user.global_logout_at:
            return None
            
    return user


class RequiresRole:
    """Dependency factory for role-based access control (RBAC)."""

    def __init__(self, *allowed_roles: str):
        self.allowed_roles = allowed_roles

    async def __call__(self, user: "User" = Depends(get_current_user)) -> "User":
        if user.perfil not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: permissão insuficiente",
            )
        return user
