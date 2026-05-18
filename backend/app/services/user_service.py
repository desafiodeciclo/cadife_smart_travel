import uuid
from typing import Optional
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.user import User, UserProfileUpdate, RegisterRequest, UserPerfil


async def create_user(
    db: AsyncSession,
    data: Optional[RegisterRequest] = None,
    *,
    nome: Optional[str] = None,
    email: Optional[str] = None,
    password: Optional[str] = None,
    role: str = "cliente",
) -> User:
    """
    Creates a new user. Supports both RegisterRequest schema and direct keyword arguments.
    """
    if data is not None:
        user = User(
            email=data.email,
            nome=data.name,
            hashed_password=hash_password(data.password.get_secret_value()),
            perfil=role,
        )
    else:
        user = User(
            nome=nome,
            email=email,
            hashed_password=hash_password(password) if password else "",
            perfil=role,
        )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()


async def update_password(db: AsyncSession, user: User, new_password_plain: str) -> User:
    """Updates user password and invalidates active sessions by updating global_logout_at."""
    user = await db.merge(user)
    user.hashed_password = hash_password(new_password_plain)
    user.global_logout_at = datetime.now(timezone.utc).replace(microsecond=0)
    await db.commit()
    await db.refresh(user)
    return user


async def update_fcm_token(db: AsyncSession, user: User, fcm_token: str) -> User:
    user = await db.merge(user)
    user.fcm_token = fcm_token
    await db.commit()
    await db.refresh(user)
    return user


async def update_user_avatar(db: AsyncSession, user: User, avatar_url: str) -> User:
    user = await db.merge(user)
    user.avatar_url = avatar_url
    await db.commit()
    await db.refresh(user)
    return user


async def update_user_profile(
    db: AsyncSession, user: User, data: UserProfileUpdate
) -> User:
    user = await db.merge(user)
    if data.nome is not None:
        user.nome = data.nome
    if data.tipo_viagem is not None:
        user.tipo_viagem = data.tipo_viagem
    if data.preferencias is not None:
        user.preferencias = data.preferencias
    if data.tem_passaporte is not None:
        user.tem_passaporte = data.tem_passaporte
    if data.bio is not None:
        user.bio = data.bio
    if data.avatar_url is not None:
        user.avatar_url = data.avatar_url
    await db.commit()
    await db.refresh(user)
    return user


async def update_bio(db: AsyncSession, user: User, bio: str) -> User:
    """Updates consultor bio (max 500 chars enforced by schema)."""
    user = await db.merge(user)
    user.bio = bio
    await db.commit()
    await db.refresh(user)
    return user


async def update_avatar_url(db: AsyncSession, user: User, url: str) -> User:
    """Updates avatar URL after a successful profile-photo upload."""
    user = await db.merge(user)
    user.avatar_url = url
    await db.commit()
    await db.refresh(user)
    return user
