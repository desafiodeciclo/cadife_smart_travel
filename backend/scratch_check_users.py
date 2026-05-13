import asyncio
from sqlalchemy import text
from app.infrastructure.persistence.database import AsyncSessionLocal

async def check():
    async with AsyncSessionLocal() as db:
        res = await db.execute(text("SELECT email, perfil FROM users"))
        users = res.all()
        print(f"USERS: {users}")

if __name__ == "__main__":
    asyncio.run(check())
