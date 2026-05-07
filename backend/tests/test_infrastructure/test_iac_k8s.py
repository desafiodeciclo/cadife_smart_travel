import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from app.services import health_service
import bootstrap

@pytest.mark.asyncio
async def test_health_service_database_check():
    """Valida se o serviço de saúde detecta falha/sucesso no banco."""
    with patch("app.services.health_service.engine") as mock_engine:
        # Caso 1: Sucesso
        mock_conn = AsyncMock()
        mock_engine.connect.return_value.__aenter__.return_value = mock_conn
        
        res = await health_service.check_database()
        assert res is True
        
        # Caso 2: Falha
        mock_engine.connect.side_effect = Exception("DB Down")
        res = await health_service.check_database()
        assert res is False

@pytest.mark.asyncio
async def test_health_service_redis_check():
    """Valida se o serviço de saúde detecta falha/sucesso no Redis."""
    with patch("redis.asyncio.from_url", new_callable=AsyncMock) as mock_from_url:
        # Caso 1: Sucesso
        mock_redis = AsyncMock()
        mock_redis.ping = AsyncMock(return_value=True)
        mock_redis.close = AsyncMock()
        mock_from_url.return_value = mock_redis
        
        res = await health_service.check_redis()
        assert res is True
        
        # Caso 2: Falha
        mock_redis.ping.side_effect = Exception("Redis Down")
        res = await health_service.check_redis()
        assert res is False

def test_bootstrap_logic():
    """Testa se o script de bootstrap chama as migrações e o servidor."""
    with patch("subprocess.run") as mock_run, \
         patch("os.execvp") as mock_exec:
        
        mock_run.return_value.returncode = 0
        bootstrap.run_migrations()
        assert mock_run.called
        
        try:
            bootstrap.start_server()
        except Exception:
            pass
        assert mock_exec.called

def test_bootstrap_migration_failure():
    """Garante que o bootstrap para se a migração falhar."""
    with patch("subprocess.run") as mock_run, \
         patch("sys.exit") as mock_exit:
        
        mock_run.return_value.returncode = 1
        bootstrap.run_migrations()
        assert mock_exit.called
