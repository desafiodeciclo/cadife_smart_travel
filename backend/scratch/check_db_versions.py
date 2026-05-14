import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def check():
    engine = create_async_engine('postgresql+asyncpg://cadife:cadife@localhost:5433/cadife_db')
    try:
        async with engine.connect() as conn:
            res = await conn.execute(text('SELECT version_num FROM alembic_version'))
            versions = res.scalars().all()
            print(f"Current versions in DB: {versions}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check())
