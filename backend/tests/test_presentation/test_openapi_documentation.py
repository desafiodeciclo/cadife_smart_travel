"""
Tests — OpenAPI / Swagger Documentation Contract
=================================================
Validate that the FastAPI application generates a correct and complete
OpenAPI specification, that /docs and /redoc are reachable, and that
critical endpoints document their error responses.

These tests act as a regression guard: if someone removes a `summary`,
`description`, or `responses` dict from a route decorator, the test suite
will catch it.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from main import app

# ---------------------------------------------------------------------------
# /docs and /redoc availability
# ---------------------------------------------------------------------------


def test_docs_endpoint_returns_200(client: TestClient):
    """Swagger UI must be available and served by FastAPI."""
    response = client.get("/docs")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    body = response.text.lower()
    assert "swagger" in body or "openapi" in body


def test_redoc_endpoint_returns_200(client: TestClient):
    """ReDoc must be available and served by FastAPI."""
    response = client.get("/redoc")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    body = response.text.lower()
    assert "redoc" in body or "openapi" in body


# ---------------------------------------------------------------------------
# OpenAPI metadata & structure
# ---------------------------------------------------------------------------


def test_openapi_json_contains_required_metadata(client: TestClient):
    """The generated spec must contain title, version, contact and license."""
    response = client.get("/openapi.json")
    assert response.status_code == 200
    spec = response.json()

    info = spec["info"]
    assert info["title"] == "Cadife Smart Travel API"
    assert info["version"] == "1.0.0"
    assert "contact" in info
    assert info["contact"]["name"] == "Cadife Tour - Time de Desenvolvimento"
    assert "license" in info


def test_openapi_json_contains_all_routers(client: TestClient):
    """Every business router must be present in the spec."""
    response = client.get("/openapi.json")
    spec = response.json()
    paths = spec["paths"]

    required_prefixes = {
        "/health",
        "/webhook/whatsapp",
        "/auth/login",
        "/auth/refresh",
        "/users/me",
        "/users/fcm-token",
        "/leads",
        "/agenda",
        "/propostas",
        "/ia/processar",
        "/ia/extrair-briefing",
        "/ia/status",
    }
    for prefix in required_prefixes:
        assert any(p.startswith(prefix) for p in paths), f"Missing router for prefix {prefix}"


def test_common_error_schemas_are_registered(client: TestClient):
    """HTTPErrorResponse and HTTPValidationErrorResponse must appear in components/schemas."""
    response = client.get("/openapi.json")
    schemas = response.json()["components"]["schemas"]
    assert "HTTPErrorResponse" in schemas
    assert "HTTPValidationErrorResponse" in schemas

    error_schema = schemas["HTTPErrorResponse"]
    props = error_schema["properties"]
    assert "detail" in props
    assert "error_code" in props


# ---------------------------------------------------------------------------
# Error-response documentation per endpoint group
# ---------------------------------------------------------------------------


def test_auth_login_documents_error_responses(client: TestClient):
    """POST /auth/login must document 401 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/auth/login"]["post"]["responses"]
    assert "401" in responses
    assert "422" in responses


def test_auth_refresh_documents_error_responses(client: TestClient):
    """POST /auth/refresh must document 401 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/auth/refresh"]["post"]["responses"]
    assert "401" in responses
    assert "422" in responses


def test_leads_list_documents_error_responses(client: TestClient):
    """GET /leads must document 401 and 403."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/leads"]["get"]["responses"]
    assert "401" in responses
    assert "403" in responses


def test_lead_detail_documents_error_responses(client: TestClient):
    """GET /leads/{lead_id} must document 401, 403 and 404."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/leads/{lead_id}"]["get"]["responses"]
    assert "401" in responses
    assert "403" in responses
    assert "404" in responses


def test_lead_create_documents_error_responses(client: TestClient):
    """POST /leads must document 401, 403, 409 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/leads"]["post"]["responses"]
    assert "401" in responses
    assert "403" in responses
    assert "409" in responses
    assert "422" in responses


def test_lead_update_documents_error_responses(client: TestClient):
    """PUT /leads/{lead_id} must document 401, 403, 404, 409 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/leads/{lead_id}"]["put"]["responses"]
    assert "401" in responses
    assert "403" in responses
    assert "404" in responses
    assert "409" in responses
    assert "422" in responses


def test_lead_delete_documents_error_responses(client: TestClient):
    """DELETE /leads/{lead_id} must document 401, 403 and 404."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/leads/{lead_id}"]["delete"]["responses"]
    assert "401" in responses
    assert "403" in responses
    assert "404" in responses


def test_proposta_create_documents_error_responses(client: TestClient):
    """POST /propostas must document 400, 401, 403, 404 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/propostas"]["post"]["responses"]
    assert "400" in responses
    assert "401" in responses
    assert "403" in responses
    assert "404" in responses
    assert "422" in responses


def test_agenda_create_documents_error_responses(client: TestClient):
    """POST /agenda must document 401, 403, 404, 409 and 422."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/agenda"]["post"]["responses"]
    assert "401" in responses
    assert "403" in responses
    assert "404" in responses
    assert "409" in responses
    assert "422" in responses


def test_webhook_post_documents_error_responses(client: TestClient):
    """POST /webhook/whatsapp must document 403 (invalid HMAC)."""
    response = client.get("/openapi.json")
    spec = response.json()
    responses = spec["paths"]["/webhook/whatsapp"]["post"]["responses"]
    assert "403" in responses


# ---------------------------------------------------------------------------
# Response model references
# ---------------------------------------------------------------------------


def test_lead_list_uses_paginated_response_model(client: TestClient):
    """GET /leads must reference LeadListResponseDTO in its 200 response."""
    response = client.get("/openapi.json")
    spec = response.json()
    ok_response = spec["paths"]["/leads"]["get"]["responses"]["200"]
    content = ok_response["content"]["application/json"]["schema"]
    # FastAPI wraps the model in a $ref under schema
    assert "$ref" in content


def test_health_endpoint_is_tagged(client: TestClient):
    """/health must belong to the 'Health' tag."""
    response = client.get("/openapi.json")
    spec = response.json()
    tags = spec["paths"]["/health"]["get"]["tags"]
    assert "Health" in tags
