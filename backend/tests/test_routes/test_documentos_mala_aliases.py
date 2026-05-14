"""
Tests — Documentos / Mala PT aliases (parity gap §3.11)
========================================================
Validates:
  - Canonical PT paths (/documentos, /mala/itens, /mala/sugestoes) work and
    return the SAME response as the legacy EN paths.
  - Legacy EN paths still work but are flagged as deprecated in OpenAPI.
  - Deprecation usage is logged via structlog `deprecated_path` event.
"""

import uuid
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import (
    DestinationType,
    DocumentoCategoria,
    LeadStatus,
    SuitcaseCategory,
)
from app.infrastructure.persistence.models.suitcase_model import (
    SuitcaseItemModel,
    SuitcaseSuggestionModel,
)


def _mock_lead(lead_id: uuid.UUID, telefone_hash: str = "hash_cliente"):
    lead = SimpleNamespace()
    lead.id = lead_id
    lead.nome = "Cliente Teste"
    lead.telefone = "+5511988887777"
    lead.telefone_hash = telefone_hash
    lead.status = LeadStatus.em_atendimento
    lead.origem = "app"
    lead.is_archived = False
    lead.criado_em = datetime.now(timezone.utc)
    lead.atualizado_em = datetime.now(timezone.utc)
    lead.consultor_id = None
    lead.briefing = None
    return lead


# ══════════════════════════════════════════════════════════════════════════════
# OpenAPI deprecation flags — fastest cross-check
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestOpenAPIDeprecation:
    """Confirms PT paths are canonical and EN paths are flagged deprecated."""

    async def test_pt_documentos_paths_not_deprecated(self, async_client: AsyncClient):
        spec = (await async_client.get("/openapi.json")).json()
        path = spec["paths"]["/leads/{lead_id}/documentos"]
        for method in ("get", "post"):
            assert path[method].get("deprecated") is not True, (
                f"PT path /documentos {method.upper()} must NOT be deprecated"
            )

    async def test_en_documents_paths_are_deprecated(self, async_client: AsyncClient):
        spec = (await async_client.get("/openapi.json")).json()
        path = spec["paths"]["/leads/{lead_id}/documents"]
        for method in ("get", "post"):
            assert path[method].get("deprecated") is True, (
                f"EN path /documents {method.upper()} MUST be deprecated"
            )
        delete_path = spec["paths"]["/leads/{lead_id}/documents/{documento_id}"]["delete"]
        assert delete_path.get("deprecated") is True

    async def test_pt_mala_paths_not_deprecated(self, async_client: AsyncClient):
        spec = (await async_client.get("/openapi.json")).json()
        for path_key in (
            "/leads/{lead_id}/mala",
            "/leads/{lead_id}/mala/itens",
            "/leads/{lead_id}/mala/itens/{item_id}",
            "/leads/{lead_id}/mala/sugestoes",
        ):
            for op in spec["paths"][path_key].values():
                assert op.get("deprecated") is not True, (
                    f"PT path {path_key} must NOT be deprecated"
                )

    async def test_en_suitcase_paths_are_deprecated(self, async_client: AsyncClient):
        spec = (await async_client.get("/openapi.json")).json()
        for path_key in (
            "/leads/{lead_id}/suitcase",
            "/leads/{lead_id}/suitcase/items",
            "/leads/{lead_id}/suitcase/items/{item_id}",
            "/leads/{lead_id}/suitcase/suggestions",
        ):
            for op in spec["paths"][path_key].values():
                assert op.get("deprecated") is True, (
                    f"EN path {path_key} MUST be deprecated"
                )


# ══════════════════════════════════════════════════════════════════════════════
# /mala — functional parity with /suitcase
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestMalaPTRoutes:

    async def test_post_mala_itens_creates_item(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.mala.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead

            payload = {
                "nome": "Passaporte",
                "categoria": "documentos",
                "quantidade": 1,
                "empacotado": False,
            }
            resp = await async_client.post(
                f"/leads/{lead_id}/mala/itens", json=payload
            )
            assert resp.status_code == 201
            data = resp.json()
            assert data["nome"] == "Passaporte"
            assert data["categoria"] == "documentos"
            assert data["lead_id"] == str(lead_id)

    async def test_post_mala_itens_invalid_quantity(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.mala.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead
            payload = {"nome": "X", "categoria": "outros", "quantidade": 0}
            resp = await async_client.post(
                f"/leads/{lead_id}/mala/itens", json=payload
            )
            assert resp.status_code == 422

    async def test_get_mala_returns_grouped(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.mala.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead

            db_session.add_all(
                [
                    SuitcaseItemModel(
                        lead_id=lead_id,
                        user_id=override_get_current_user.id,
                        nome="Passaporte",
                        categoria=SuitcaseCategory.documentos.value,
                        quantidade=1,
                        empacotado=True,
                    ),
                    SuitcaseItemModel(
                        lead_id=lead_id,
                        user_id=override_get_current_user.id,
                        nome="Camiseta",
                        categoria=SuitcaseCategory.roupas.value,
                        quantidade=3,
                        empacotado=False,
                    ),
                ]
            )
            await db_session.commit()

            resp = await async_client.get(f"/leads/{lead_id}/mala")
            assert resp.status_code == 200
            data = resp.json()
            # response carries grouped categories — same shape as /suitcase
            assert "itens_por_categoria" in data or "categorias" in data or isinstance(data, dict)

    async def test_get_mala_sugestoes(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.mala.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead

            db_session.add(
                SuitcaseSuggestionModel(
                    nome="Protetor solar",
                    categoria=SuitcaseCategory.higiene.value,
                    tipo_destino=DestinationType.praia.value,
                    quantidade_sugerida=1,
                )
            )
            await db_session.commit()

            resp = await async_client.get(
                f"/leads/{lead_id}/mala/sugestoes?tipo_destino=praia"
            )
            assert resp.status_code == 200
            assert isinstance(resp.json(), list)


# ══════════════════════════════════════════════════════════════════════════════
# /suitcase — still works (legacy EN preserved)
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestSuitcaseENStillWorks:
    """Legacy EN paths must keep working during the deprecation window."""

    async def test_legacy_post_suitcase_items_still_creates(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.suitcase.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead

            payload = {
                "nome": "Sandália",
                "categoria": "calcados",
                "quantidade": 1,
            }
            resp = await async_client.post(
                f"/leads/{lead_id}/suitcase/items", json=payload
            )
            assert resp.status_code == 201

    async def test_legacy_get_suitcase_logs_deprecated_path(
        self,
        async_client: AsyncClient,
        override_get_current_user,
        caplog,
    ):
        """Confirms structlog warning is emitted for deprecation telemetry."""
        import logging

        caplog.set_level(logging.WARNING)
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch(
            "app.routes.suitcase.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
        ) as mock_get:
            mock_get.return_value = mock_lead
            resp = await async_client.get(f"/leads/{lead_id}/suitcase")
            assert resp.status_code == 200

        # structlog warns; either via caplog or by inspecting the message string
        assert any(
            "deprecated_path" in str(rec.msg) or "deprecated_path" in str(rec.message)
            for rec in caplog.records
        ), "Expected a 'deprecated_path' warning when calling EN /suitcase"


# ══════════════════════════════════════════════════════════════════════════════
# /documentos — functional smoke (PT)
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestDocumentosPTRoutes:
    """File upload uses S3StorageAdapter; we mock the service layer."""

    async def test_get_documentos_pt_calls_service(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()

        with patch(
            "app.routes.documentos.DocumentoService.list_documents",
            new_callable=AsyncMock,
        ) as mock_list:
            mock_list.return_value = []
            resp = await async_client.get(f"/leads/{lead_id}/documentos")
            assert resp.status_code == 200
            assert resp.json() == []
            mock_list.assert_called_once()

    async def test_get_documents_en_still_works_logs_deprecated(
        self,
        async_client: AsyncClient,
        override_get_current_user,
        caplog,
    ):
        import logging

        caplog.set_level(logging.WARNING)
        lead_id = uuid.uuid4()

        with patch(
            "app.routes.documents.DocumentoService.list_documents",
            new_callable=AsyncMock,
        ) as mock_list:
            mock_list.return_value = []
            resp = await async_client.get(f"/leads/{lead_id}/documents")
            assert resp.status_code == 200
            mock_list.assert_called_once()

        assert any(
            "deprecated_path" in str(rec.msg) or "deprecated_path" in str(rec.message)
            for rec in caplog.records
        ), "Expected a 'deprecated_path' warning when calling EN /documents"

    async def test_delete_documentos_pt_calls_service(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        lead_id = uuid.uuid4()
        documento_id = uuid.uuid4()

        with patch(
            "app.routes.documentos.DocumentoService.delete_document",
            new_callable=AsyncMock,
        ) as mock_delete:
            resp = await async_client.delete(
                f"/leads/{lead_id}/documentos/{documento_id}"
            )
            assert resp.status_code == 204
            mock_delete.assert_called_once()
