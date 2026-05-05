"""
Testes E2E para a rota de Health Check.
=========================================
Rota pública (sem autenticação).
"""


def test_health_check_public_access(client):
    """Testa se a rota /health está acessível sem autenticação."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "cadife-smart-travel"
    assert "version" in data
    assert "env" in data


def test_health_check_response_structure(client):
    """Testa se a resposta do /health contém todos os campos esperados."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    expected_keys = {"status", "service", "version", "env"}
    assert set(data.keys()) == expected_keys
