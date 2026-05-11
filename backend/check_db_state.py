import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def check_db():
    url = "postgresql+asyncpg://cadife:cadife@localhost:5433/cadife_db"
    engine = create_async_engine(url)
    
    print("--- DB DIAGNOSTIC START ---")
    
    # Check current version
    async with engine.connect() as conn:
        try:
            res = await conn.execute(text("SELECT version_num FROM alembic_version"))
            version = res.scalar()
            print(f"Current Alembic Version in DB: {version}")
        except Exception:
            print("Table 'alembic_version' does not exist.")

    # Check if basic tables exist
    for table in ['leads', 'briefings', 'interacoes', 'propostas', 'users']:
        async with engine.connect() as conn:
            try:
                res = await conn.execute(text(f"SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='{table}')"))
                if res.scalar():
                    print(f"Table '{table}' exists")
                else:
                    print(f"Table '{table}' DOES NOT exist")
            except Exception as e:
                print(f"Error checking {table}: {e}")

    # Check if any enums exist
    async with engine.connect() as conn:
        try:
            res = await conn.execute(text("SELECT typname FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public' AND t.typtype = 'e'"))
            enums = [r[0] for r in res.fetchall()]
            if enums:
                print(f"EXISTING ENUMS IN DB: {enums}")
            else:
                print("NO ENUMS FOUND IN DB (Clean).")
        except Exception as e:
            print(f"Error checking enums: {e}")

    print("--- DB DIAGNOSTIC END ---")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check_db())
