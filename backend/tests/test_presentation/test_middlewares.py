import pytest
import asyncio
from fastapi import FastAPI, APIRouter
from httpx import AsyncClient, ASGITransport
from app.presentation.middlewares.request_id import RequestIdMiddleware
from app.presentation.middlewares.timeout import TimeoutMiddleware

# App de teste isolado para middlewares
test_app = FastAPI()
test_app.add_middleware(RequestIdMiddleware)
test_app.add_middleware(TimeoutMiddleware)

router = APIRouter()

@router.get("/fast")
async def fast_route():
    return {"status": "ok"}

@router.get("/slow")
async def slow_route():
    await asyncio.sleep(2) # Simula delay
    return {"status": "too_slow"}

@router.post("/webhook/test")
async def webhook_route():
    await asyncio.sleep(2) # Simula delay no webhook
    return {"status": "webhook_ok"}

test_app.include_router(router)

@pytest.mark.asyncio
async def test_request_id_middleware():
    """Testa se o header X-Request-ID est presente na resposta."""
    async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
        response = await ac.get("/fast")
    
    assert response.status_code == 200
    assert "X-Request-ID" in response.headers
    # Verifica se  um UUID v4 (aproximadamente)
    rid = response.headers["X-Request-ID"]
    assert len(rid) == 36

@pytest.mark.asyncio
async def test_timeout_middleware_standard_pass():
    """Testa se uma rota dentro do tempo limite passa (global default 30s)."""
    async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
        response = await ac.get("/fast")
    assert response.status_code == 200

@pytest.mark.asyncio
async def test_timeout_middleware_webhook_enforcement(monkeypatch):
    """Testa se o webhook corta em 4.5s conforme configurado."""
    from app.core.config import get_settings
    settings = get_settings()
    # Foramos um timeout curto para o teste no demorar 4.5s
    monkeypatch.setattr(settings, "WEBHOOK_TIMEOUT_SECONDS", 0.5)
    
    async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
        # /webhook/test deve disparar o timeout de 0.5s (mockado)
        response = await ac.post("/webhook/test")
    
    assert response.status_code == 504
    assert "Request timeout" in response.json()["detail"]

@pytest.mark.asyncio
async def test_timeout_middleware_global_enforcement(monkeypatch):
    """Testa se o timeout global (30s) corta rotas lentas."""
    from app.core.config import get_settings
    settings = get_settings()
    # Foramos um timeout curto para o teste
    monkeypatch.setattr(settings, "REQUEST_TIMEOUT_SECONDS", 0.5)
    
    async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
        response = await ac.get("/slow")
    
    assert response.status_code == 504
    assert "Request timeout" in response.json()["detail"]
