import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def check():
    engine = create_async_engine('postgresql+asyncpg://cadife:cadife@localhost:5433/cadife_db')
    try:
        async with engine.connect() as conn:
            res = await conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'aya_toggle_history')"))
            print(f"Table 'aya_toggle_history' exists: {res.scalar()}")
            
            res = await conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'aya_ativo')"))
            print(f"Column 'leads.aya_ativo' exists: {res.scalar()}")
            
            res = await conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'bio')"))
            print(f"Column 'users.bio' exists: {res.scalar()}")

            res = await conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'revoked_tokens')"))
            print(f"Table 'revoked_tokens' exists: {res.scalar()}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check())
