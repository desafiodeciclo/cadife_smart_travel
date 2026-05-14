import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.presentation.schemas.user_schema import UserProfileUpdate


async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()


async def update_fcm_token(db: AsyncSession, user: User, fcm_token: str) -> User:
    user.fcm_token = fcm_token
    await db.commit()
    await db.refresh(user)
    return user


async def update_user_profile(
    db: AsyncSession, user: User, data: UserProfileUpdate
) -> User:
    if data.nome is not None:
        user.nome = data.nome
    if data.tipo_viagem is not None:
        user.tipo_viagem = data.tipo_viagem
    if data.preferencias is not None:
        user.preferencias = data.preferencias
    if data.tem_passaporte is not None:
        user.tem_passaporte = data.tem_passaporte
    await db.commit()
    await db.refresh(user)
    return user


async def update_bio(db: AsyncSession, user: User, bio: str) -> User:
    """Updates consultor bio (max 500 chars enforced by schema)."""
    user.bio = bio
    await db.commit()
    await db.refresh(user)
    return user


async def update_avatar_url(db: AsyncSession, user: User, url: str) -> User:
    """Updates avatar URL after a successful profile-photo upload."""
    user.avatar_url = url
    await db.commit()
    await db.refresh(user)
    return user
