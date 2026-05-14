import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone

from app.models.user import User, UserProfileUpdate, RegisterRequest, UserPerfil
from app.core.security import hash_password


async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()


async def create_user(db: AsyncSession, data: RegisterRequest, role: str = UserPerfil.cliente) -> User:
    user = User(
        email=data.email,
        nome=data.name,
        hashed_password=hash_password(data.password.get_secret_value()),
        perfil=role
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def update_password(db: AsyncSession, user: User, new_password_plain: str) -> User:
    user.hashed_password = hash_password(new_password_plain)
    user.global_logout_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)
    return user


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
