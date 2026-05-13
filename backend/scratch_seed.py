
import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.infrastructure.config.settings import get_settings
from app.infrastructure.security.jwt import hash_password
from app.models.user import User, UserPerfil
from app.infrastructure.persistence.database import Base
from sqlalchemy.pool import NullPool

async def create_user():
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, poolclass=NullPool)
    
    # CRIAR TABELAS PRIMEIRO
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        print("TABELAS_CRIADAS")

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        email = "admin@cadifetoure.com.br"
        hashed = hash_password("Cadife@2026")
        admin = User(
            id=uuid.uuid4(),
            email=email,
            nome="Admin Teste",
            hashed_password=hashed,
            perfil=UserPerfil.admin,
            is_active=True
        )
        session.add(admin)
        try:
            await session.commit()
            print(f"USUARIO_CRIADO:{email}")
        except Exception as e:
            await session.rollback()
            print(f"ERRO_OU_EXISTENTE:{str(e)}")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(create_user())
