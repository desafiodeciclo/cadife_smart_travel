"""
Testes da Feature Suitcase (Minha Mala)
========================================
Validam CRUD de itens, agrupamento por categoria, sugestões determinísticas
e controle de acesso (RBAC/Ownership).
"""

import uuid
import pytest
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch, MagicMock
from types import SimpleNamespace

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import SuitcaseCategory, DestinationType, LeadStatus
from app.infrastructure.persistence.models.suitcase_model import (
    SuitcaseItemModel,
    SuitcaseSuggestionModel,
)
from app.infrastructure.persistence.models.user_model import UserModel


# ── Helpers ───────────────────────────────────────────────────────────────


def _mock_lead(lead_id: uuid.UUID, telefone_hash: str = "hash_cliente", destino: str = None):
    """Retorna um objeto mock compatível com o uso no route handler."""
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

    if destino:
        briefing = SimpleNamespace()
        briefing.destino = destino
        briefing.completude_pct = 70
        lead.briefing = briefing
    else:
        lead.briefing = None

    return lead


# ── Testes de Rotas ───────────────────────────────────────────────────────


@pytest.mark.asyncio
class TestSuitcaseItems:
    async def test_create_item_success(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        """POST /leads/{id}/suitcase/items cria item com quantidade >= 1."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            payload = {
                "nome": "Passaporte",
                "categoria": "documentos",
                "quantidade": 1,
                "empacotado": False,
            }
            resp = await async_client.post(
                f"/leads/{lead_id}/suitcase/items", json=payload
            )
            assert resp.status_code == 201
            data = resp.json()
            assert data["nome"] == "Passaporte"
            assert data["categoria"] == "documentos"
            assert data["quantidade"] == 1
            assert data["empacotado"] is False
            assert data["lead_id"] == str(lead_id)

    async def test_create_item_invalid_quantity(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        """Validação rejeita quantidade < 1."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            payload = {"nome": "X", "categoria": "outros", "quantidade": 0}
            resp = await async_client.post(
                f"/leads/{lead_id}/suitcase/items", json=payload
            )
            assert resp.status_code == 422

    async def test_get_suitcase_grouped(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /leads/{id}/suitcase retorna itens agrupados por categoria."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            # Pre-popula dois itens em categorias diferentes
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

            resp = await async_client.get(f"/leads/{lead_id}/suitcase")
            assert resp.status_code == 200
            data = resp.json()
            assert data["total_items"] == 2
            assert data["total_packed"] == 1
            assert len(data["items_by_category"]["documentos"]) == 1
            assert len(data["items_by_category"]["roupas"]) == 1

    async def test_update_item_status(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """PATCH marca item como empacotado."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            item = SuitcaseItemModel(
                lead_id=lead_id,
                user_id=override_get_current_user.id,
                nome="Carregador",
                categoria=SuitcaseCategory.eletronicos.value,
                quantidade=1,
                empacotado=False,
            )
            db_session.add(item)
            await db_session.commit()
            await db_session.refresh(item)

            resp = await async_client.patch(
                f"/leads/{lead_id}/suitcase/items/{item.id}",
                json={"empacotado": True},
            )
            assert resp.status_code == 200
            assert resp.json()["empacotado"] is True

    async def test_delete_item(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """DELETE remove item da mala."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            item = SuitcaseItemModel(
                lead_id=lead_id,
                user_id=override_get_current_user.id,
                nome="Escova de dentes",
                categoria=SuitcaseCategory.higiene.value,
                quantidade=1,
                empacotado=False,
            )
            db_session.add(item)
            await db_session.commit()
            await db_session.refresh(item)

            resp = await async_client.delete(
                f"/leads/{lead_id}/suitcase/items/{item.id}"
            )
            assert resp.status_code == 204

            # Confirma remoção
            resp_get = await async_client.get(f"/leads/{lead_id}/suitcase")
            assert resp_get.json()["total_items"] == 0

    async def test_rbac_client_cannot_access_other_lead(
        self,
        async_client: AsyncClient,
    ):
        """Cliente recebe 403 ao tentar acessar mala de lead não vinculado."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id, telefone_hash="hash_outro")

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            # Mock user cliente com telefone diferente do lead
            from app.infrastructure.security.dependencies import get_current_user
            from main import app

            mock_client = SimpleNamespace()
            mock_client.id = uuid.uuid4()
            mock_client.nome = "Cliente"
            mock_client.email = "cliente@example.com"
            mock_client.hashed_password = "x"
            mock_client.telefone = "+5511988887777"
            mock_client.perfil = "cliente"
            mock_client.is_active = True
            mock_client.criado_em = datetime.now(timezone.utc)

            async def _mock():
                return mock_client

            app.dependency_overrides[get_current_user] = _mock
            try:
                resp = await async_client.get(f"/leads/{lead_id}/suitcase")
                assert resp.status_code == 403
            finally:
                app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
class TestSuitcaseSuggestions:
    async def test_get_suggestions_by_query_param(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /suggestions?tipo_destino=praia retorna itens esperados."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id)

        # Pre-popula sugestões
        db_session.add_all(
            [
                SuitcaseSuggestionModel(
                    tipo_destino=DestinationType.praia.value,
                    categoria=SuitcaseCategory.higiene.value,
                    nome="Protetor Solar",
                    quantidade_sugerida=1,
                ),
                SuitcaseSuggestionModel(
                    tipo_destino=DestinationType.praia.value,
                    categoria=SuitcaseCategory.acessorios.value,
                    nome="Óculos de Sol",
                    quantidade_sugerida=1,
                ),
            ]
        )
        await db_session.commit()

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            resp = await async_client.get(
                f"/leads/{lead_id}/suitcase/suggestions",
                params={"tipo_destino": "praia"},
            )
            assert resp.status_code == 200
            data = resp.json()
            nomes = {s["nome"] for s in data}
            assert "Protetor Solar" in nomes
            assert "Óculos de Sol" in nomes

    async def test_get_suggestions_inferred_from_briefing(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """Se tipo_destino não é informado, infere do briefing do lead."""
        lead_id = uuid.uuid4()
        mock_lead = _mock_lead(lead_id, destino="Rio de Janeiro - Praia")

        db_session.add_all(
            [
                SuitcaseSuggestionModel(
                    tipo_destino=DestinationType.praia.value,
                    categoria=SuitcaseCategory.higiene.value,
                    nome="Protetor Solar",
                    quantidade_sugerida=1,
                ),
            ]
        )
        await db_session.commit()

        with patch("app.routes.suitcase.lead_service.get_lead_by_id", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_lead

            resp = await async_client.get(
                f"/leads/{lead_id}/suitcase/suggestions"
            )
            assert resp.status_code == 200
            data = resp.json()
            nomes = {s["nome"] for s in data}
            assert "Protetor Solar" in nomes
