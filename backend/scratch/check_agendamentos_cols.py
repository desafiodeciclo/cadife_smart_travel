import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def f():
    url = os.getenv("DATABASE_URL")
    if not url:
        print("DATABASE_URL is not set!")
        return
    engine = create_async_engine(url)
    async with engine.connect() as c:
        r = await c.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='agendamentos'"))
        for row in r.fetchall():
            print(row)
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(f())
