"""
UserRepository — Infrastructure/Persistence Layer
==================================================
Concrete async repository for user authentication and profile management.
"""
import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import structlog

from app.infrastructure.persistence.abstract_repository import AbstractRepository
from app.infrastructure.persistence.models.user_model import UserModel

logger = structlog.get_logger()


class UserRepository(AbstractRepository[UserModel]):
    model = UserModel

    def __init__(self, session: AsyncSession) -> None:
        super().__init__(session)

    async def get_by_id(self, user_id: uuid.UUID) -> Optional[UserModel]:
        return await self._session.get(UserModel, user_id)

    async def get_by_email(self, email: str) -> Optional[UserModel]:
        result = await self._session.execute(
            select(UserModel).where(UserModel.email == email, UserModel.is_active.is_(True))
        )
        return result.scalar_one_or_none()

    async def create(
        self,
        email: str,
        nome: str,
        hashed_password: str,
        perfil: str = "agencia",
    ) -> UserModel:
        user = UserModel(
            email=email,
            nome=nome,
            hashed_password=hashed_password,
            perfil=perfil,
        )
        self._session.add(user)
        await self._session.flush()
        await self._session.refresh(user)
        logger.info("user_created", user_id=str(user.id), email=email, perfil=perfil)
        return user

    async def update_fcm_token(self, user_id: uuid.UUID, fcm_token: str) -> Optional[UserModel]:
        user = await self.get_by_id(user_id)
        if user:
            user.fcm_token = fcm_token
            await self._session.flush()
        return user

    async def list_active_with_fcm_token(self, perfil: Optional[str] = None) -> list[UserModel]:
        stmt = select(UserModel).where(
            UserModel.is_active.is_(True),
            UserModel.fcm_token.isnot(None),
        )
        if perfil:
            stmt = stmt.where(UserModel.perfil == perfil)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())
