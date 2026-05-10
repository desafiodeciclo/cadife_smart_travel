"""
Tests — OpenAPI Snapshot / Synchronisation
===========================================
Guarantee that the committed `docs/api/openapi.json` is byte-for-byte
synchronized with the live `app.openapi()` output.

If this test fails, regenerate the file with:

    python -c "import json; from main import app; json.dump(app.openapi(), open('docs/api/openapi.json', 'w'), ensure_ascii=False, indent=2)"

or simply run the app and download /openapi.json.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from main import app

PROJECT_ROOT = Path(__file__).resolve().parents[3]
SNAPSHOT_PATH = PROJECT_ROOT / "docs" / "api" / "openapi.json"


def _normalise(spec: dict) -> str:
    """Return a deterministic JSON string (sorted keys, no trailing whitespace)."""
    return json.dumps(spec, ensure_ascii=False, indent=2, sort_keys=True)


def test_snapshot_file_exists():
    """The snapshot file must be present in the repository."""
    assert SNAPSHOT_PATH.exists(), (
        f"Snapshot file not found: {SNAPSHOT_PATH}\n"
        "Generate it by running the app and saving /openapi.json to docs/api/openapi.json"
    )


def test_openapi_snapshot_matches_live_code():
    """The live spec must match the committed snapshot exactly."""
    live_spec = app.openapi()
    saved_raw = SNAPSHOT_PATH.read_text(encoding="utf-8")
    saved_spec = json.loads(saved_raw)

    live_normalised = _normalise(live_spec)
    saved_normalised = _normalise(saved_spec)

    if live_normalised != saved_normalised:
        # Compute a simple diff hint (first diverging line)
        live_lines = live_normalised.splitlines()
        saved_lines = saved_normalised.splitlines()
        for i, (a, b) in enumerate(zip(live_lines, saved_lines)):
            if a != b:
                pytest.fail(
                    f"openapi.json is out of sync with the live code at line {i + 1}.\n"
                    f"  Live:  {a}\n"
                    f"  Saved: {b}\n\n"
                    "Regenerate the snapshot by running:\n"
                    "  python -c \"import json; from main import app; "
                    "json.dump(app.openapi(), open('docs/api/openapi.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=2)\""
                )

        # If lengths differ
        pytest.fail(
            "openapi.json is out of sync with the live code (different length).\n"
            "Regenerate the snapshot by running:\n"
            "  python -c \"import json; from main import app; "
            "json.dump(app.openapi(), open('docs/api/openapi.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=2)\""
        )


def test_snapshot_contains_at_least_twenty_two_paths():
    """Basic sanity check: the spec must document all business routers."""
    saved_spec = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
    assert len(saved_spec["paths"]) >= 22, (
        f"Expected at least 22 paths, found {len(saved_spec['paths'])}. "
        "Some router may have been accidentally removed."
    )


def test_snapshot_contains_error_schemas():
    """The snapshot must include the common error schemas we added."""
    saved_spec = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
    schemas = saved_spec["components"]["schemas"]
    assert "HTTPErrorResponse" in schemas
    assert "HTTPValidationErrorResponse" in schemas
