"""
Common HTTP Error Schemas — Presentation Layer
===============================================
Standardised Pydantic models for every HTTP error response documented
in the OpenAPI spec.  Used by `responses={...}` on route decorators so
that Swagger UI / ReDoc show the exact shape of each error.
"""

from typing import Optional

from pydantic import BaseModel, ConfigDict


class HTTPErrorResponse(BaseModel):
    """Generic error envelope returned by all failed requests."""

    detail: str
    error_code: Optional[str] = None

    model_config = ConfigDict(extra="forbid", json_schema_extra={
        "example": {"detail": "Descrição legível do erro", "error_code": "ERR_EXAMPLE"}
    })


class ValidationErrorItem(BaseModel):
    loc: list[str | int]
    msg: str
    type: str

    model_config = ConfigDict(extra="forbid")


class HTTPValidationErrorResponse(BaseModel):
    """Pydantic / FastAPI validation error (422)."""

    detail: list[ValidationErrorItem]

    model_config = ConfigDict(extra="forbid", json_schema_extra={
        "example": {
            "detail": [
                {"loc": ["body", "telefone"], "msg": "field required", "type": "missing"}
            ]
        }
    })
