import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def clean():
    engine = create_async_engine('postgresql+asyncpg://cadife:cadife@localhost:5433/cadife_db')
    try:
        async with engine.begin() as conn:
            await conn.execute(text('DROP TABLE IF EXISTS aya_toggle_history CASCADE'))
            print("Dropped aya_toggle_history")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(clean())
