import asyncio
import uuid
from datetime import datetime, timezone
from dotenv import load_dotenv
load_dotenv()
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.security.jwt import hash_password

async def create_admin():
    async with AsyncSessionLocal() as db:
        email = "admin@cadife.com.br"
        password = "admin_password"
        
        # Check if exists
        from sqlalchemy import select
        stmt = select(UserModel).where(UserModel.email == email)
        existing = (await db.execute(stmt)).scalar_one_or_none()
        
        if existing:
            print(f"User {email} already exists. Updating password...")
            existing.hashed_password = hash_password(password)
        else:
            user = UserModel(
                id=uuid.uuid4(),
                nome="Admin",
                email=email,
                hashed_password=hash_password(password),
                telefone="+5511988887777",
                perfil="admin",
                is_active=True,
                criado_em=datetime.now(timezone.utc)
            )
            db.add(user)
        
        await db.commit()
        print(f"Admin created/updated: {email} / {password}")

if __name__ == "__main__":
    asyncio.run(create_admin())
