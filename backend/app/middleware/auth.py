from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from app.infrastructure.config.settings import get_settings
from app.core.dependencies import get_db
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.infrastructure.persistence.models.user_model import UserModel
from datetime import datetime, timezone

settings = get_settings()
security = HTTPBearer()

async def verify_jwt(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
):
    """
    Middleware dependency to validate JWT tokens.
    Checks:
    1. Basic JWT validity and expiration.
    2. Token type (must be 'access').
    3. Blacklist (revoked_tokens table).
    4. Global logout (user.global_logout_at).
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        user_id = payload.get("sub")
        token_type = payload.get("type")
        iat = payload.get("iat")

        if user_id is None or token_type != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido"
            )

        # 1. Check Blacklist
        # Using a raw query for performance on every request
        res = await db.execute(
            text("SELECT 1 FROM revoked_tokens WHERE token = :t LIMIT 1"),
            {"t": token}
        )
        if res.scalar():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token revogado"
            )

        # 2. Check Global Logout
        # We need the user's global_logout_at
        user_res = await db.execute(
            text("SELECT global_logout_at FROM users WHERE id = :uid LIMIT 1"),
            {"uid": user_id}
        )
        global_logout_at = user_res.scalar()

        if global_logout_at and iat:
            # iat is seconds since epoch
            # global_logout_at might be a datetime object (SQLAlchemy)
            if isinstance(global_logout_at, str):
                # SQLite fallback if not using native datetime
                from dateutil import parser
                global_logout_at = parser.parse(global_logout_at)
            
            # Ensure global_logout_at is aware
            if global_logout_at.tzinfo is None:
                global_logout_at = global_logout_at.replace(tzinfo=timezone.utc)
            
            token_issued_at = datetime.fromtimestamp(iat, tz=timezone.utc)
            
            if token_issued_at <= global_logout_at:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sessão revogada (logout global)"
                )

        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado"
        )
