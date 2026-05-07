"""
Testes E2E para a rota de Health Check (K8S Probes).
===================================================
Rota pública (sem autenticação) que valida a saúde da infraestrutura.
"""
from unittest.mock import patch


def test_healthz_check_public_access(client):
    """Testa se a rota /healthz está acessível e funcional quando tudo está ok."""
    with patch("app.services.health_service.check_database") as mock_db, \
         patch("app.services.health_service.check_redis") as mock_redis:
        
        mock_db.return_value = True
        mock_redis.return_value = True
        
        response = client.get("/healthz")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["database"] == "connected"
        assert data["redis"] == "connected"
        assert "version" in data


def test_healthz_unhealthy_response(client):
    """Testa se o /healthz retorna 503 quando o banco de dados falha."""
    with patch("app.services.health_service.check_database") as mock_db, \
         patch("app.services.health_service.check_redis") as mock_redis:
        
        mock_db.return_value = False
        mock_redis.return_value = True
        
        response = client.get("/healthz")
        assert response.status_code == 503
        data = response.json()
        assert data["status"] == "error"
        assert data["database"] == "disconnected"
        assert data["redis"] == "connected"
