import asyncio
import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from dotenv import load_dotenv

import sys
import os
sys.path.append(os.path.join(os.getcwd(), "backend"))

# Load environment variables from .env
load_dotenv(os.path.join(os.getcwd(), "backend", ".env"))

from app.core.database import AsyncSessionLocal
from app.infrastructure.persistence.models.user_model import UserModel
from app.core.security import create_access_token, hash_password

async def get_test_token():
    async with AsyncSessionLocal() as db:
        # Check if test user exists
        stmt = select(UserModel).where(UserModel.email == "test@example.com")
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            user = UserModel(
                id=uuid.uuid4(),
                nome="Test User",
                email="test@example.com",
                hashed_password=hash_password("password123"),
                perfil="cliente",
                is_active=True,
                criado_em=datetime.now(timezone.utc)
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            print(f"User created: {user.id}")
        else:
            print(f"User exists: {user.id}")

        token = create_access_token(str(user.id))
        print(f"TOKEN:{token}")

if __name__ == "__main__":
    asyncio.run(get_test_token())
