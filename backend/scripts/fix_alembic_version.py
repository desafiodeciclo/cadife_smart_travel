"""
Fix Alembic Version Script
==========================
Manually updates the 'alembic_version' table to a valid revision ID.
Use this when Alembic is blocked by a missing revision in its history tree.
"""

import asyncio
import sys
import os

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.infrastructure.persistence.database import AsyncSessionLocal

async def fix():
    # The last known good revision ID in the project files
    valid_head = "e8f9a0b1c2d3"
    
    print(f"Connecting to database to fix migration version...")
    async with AsyncSessionLocal() as session:
        try:
            # Check current version
            res = await session.execute(text("SELECT version_num FROM alembic_version"))
            current = res.scalar()
            print(f"Current version in DB: {current}")
            
            # Update to valid head
            print(f"Updating alembic_version to {valid_head}...")
            await session.execute(text(f"UPDATE alembic_version SET version_num = '{valid_head}'"))
            await session.commit()
            print("Success! Database version synchronized with project files.")
        except Exception as e:
            print(f"Error updating alembic_version: {e}")
            await session.rollback()

if __name__ == "__main__":
    asyncio.run(fix())
