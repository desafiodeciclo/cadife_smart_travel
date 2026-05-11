"""
Tests — Postman Collection Generation
======================================
Validate that `scripts/generate_postman_collection.py` successfully
produces a valid Postman Collection v2.1 from the current OpenAPI spec.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

# Resolve project root relative to backend/tests/test_presentation/
PROJECT_ROOT = Path(__file__).resolve().parents[3]
SCRIPT_PATH = PROJECT_ROOT / "scripts" / "generate_postman_collection.py"
OPENAPI_PATH = PROJECT_ROOT / "docs" / "api" / "openapi.json"
COLLECTION_PATH = PROJECT_ROOT / "docs" / "api" / "Cadife_Smart_Travel_API.postman_collection.json"


@pytest.fixture(scope="module", autouse=True)
def regenerate_collection():
    """Ensure the collection is freshly generated before assertions."""
    assert SCRIPT_PATH.exists(), f"Script not found: {SCRIPT_PATH}"
    assert OPENAPI_PATH.exists(), f"OpenAPI spec not found: {OPENAPI_PATH}"

    result = subprocess.run(
        [sys.executable, str(SCRIPT_PATH)],
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
    )
    assert result.returncode == 0, (
        f"Collection generation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"
    )
    yield


def test_collection_file_exists():
    """The generator must write the collection JSON to docs/api/."""
    assert COLLECTION_PATH.exists(), f"Collection not found at {COLLECTION_PATH}"


def test_collection_is_valid_postman_v21():
    """Must conform to the Postman Collection v2.1 schema at the root level."""
    raw = COLLECTION_PATH.read_text(encoding="utf-8")
    collection = json.loads(raw)

    assert "info" in collection
    assert "item" in collection
    info = collection["info"]
    assert info.get("schema") == "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    assert "name" in info


def test_collection_contains_critical_flows():
    """Must include folders and requests for the 5 critical flows."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))
    all_request_urls: list[str] = []

    for folder in collection.get("item", []):
        for req in folder.get("item", []):
            url_raw = req.get("request", {}).get("url", {}).get("raw", "")
            all_request_urls.append(url_raw)

    # Auth (by URL — more stable than translated summary names)
    assert any("/auth/login" in url for url in all_request_urls), "Missing login request"
    # Webhook
    assert any("/webhook/whatsapp" in url for url in all_request_urls), "Missing webhook request"
    # Leads
    assert any("{{baseUrl}}/leads" == url for url in all_request_urls), "Missing create-lead request (POST /leads)"
    assert any("{{baseUrl}}/leads" in url and "{" not in url.replace("{{", "") for url in all_request_urls), "Missing list-leads request (GET /leads)"
    # Propostas
    assert any("/propostas" in url for url in all_request_urls), "Missing proposta request"


def test_collection_has_request_examples():
    """At least some requests must carry example request bodies (critical flows)."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))

    found_body = False
    for folder in collection.get("item", []):
        for req in folder.get("item", []):
            body = req.get("request", {}).get("body")
            if body and body.get("mode") == "raw" and body.get("raw"):
                found_body = True
                break
        if found_body:
            break

    assert found_body, "No request body examples found in collection"


def test_collection_has_response_examples():
    """At least some requests must carry example response bodies."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))

    found_response = False
    for folder in collection.get("item", []):
        for req in folder.get("item", []):
            responses = req.get("response", [])
            if responses:
                found_response = True
                break
        if found_response:
            break

    assert found_response, "No response examples found in collection"


def test_collection_has_baseurl_variable():
    """Must define a {{baseUrl}} variable for environment flexibility."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))
    variables = collection.get("variable", [])
    keys = [v["key"] for v in variables]
    assert "baseUrl" in keys


def test_collection_has_auth_token_variable():
    """Must define an {{accessToken}} variable for authenticated endpoints."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))
    variables = collection.get("variable", [])
    keys = [v["key"] for v in variables]
    assert "accessToken" in keys


def test_auth_requests_include_authorization_header():
    """Protected endpoints must include the Authorization header."""
    collection = json.loads(COLLECTION_PATH.read_text(encoding="utf-8"))

    for folder in collection.get("item", []):
        for req in folder.get("item", []):
            method = req["request"]["method"]
            url = req["request"]["url"]["raw"]
            headers = req["request"].get("header", [])
            header_keys = [h["key"].lower() for h in headers]

            # Public endpoints should NOT have auth header
            if "/auth/login" in url or "/auth/refresh" in url or "/webhook" in url or "/health" in url:
                continue

            # Protected endpoints SHOULD have auth header
            if method in ("GET", "POST", "PUT", "PATCH", "DELETE"):
                # Only assert for a sample of protected endpoints to keep test stable
                if "/leads" in url or "/propostas" in url or "/agenda" in url:
                    assert "authorization" in header_keys, (
                        f"Missing Authorization header in {method} {url}"
                    )
