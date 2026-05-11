import asyncio
from sqlalchemy import text
from app.infrastructure.persistence.database import AsyncSessionLocal

async def diagnose():
    async with AsyncSessionLocal() as session:
        # Check alembic_version
        try:
            res = await session.execute(text("SELECT version_num FROM alembic_version"))
            version = res.scalar()
            print(f"Current DB revision (alembic_version): {version}")
        except Exception as e:
            print(f"Error reading alembic_version: {e}")

        # Check existing tables
        try:
            res = await session.execute(text("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'"))
            tables = [row[0] for row in res.fetchall()]
            print(f"Existing tables: {', '.join(tables)}")
        except Exception as e:
            print(f"Error listing tables: {e}")

if __name__ == "__main__":
    asyncio.run(diagnose())
