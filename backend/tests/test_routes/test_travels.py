"""
Testes das Rotas de Travels (Viagens do Cliente)
=================================================
Validam listagem, filtro por status, ordenação e
controle de acesso (ownership).
"""

import uuid
from unittest.mock import patch

import pytest
from datetime import datetime, timezone, timedelta

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.travel_model import TravelModel
from app.models.documento import Documento


@pytest.mark.asyncio
class TestTravelsRoutes:
    async def test_list_travels_ordered_by_date(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /travels retorna viagens ordenadas por start_date crescente."""
        user_id = override_get_current_user.id

        # Cria viagens em ordem invertida de datas
        t1 = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Rio de Janeiro",
            start_date=datetime(2026, 8, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 8, 10, tzinfo=timezone.utc),
            status="upcoming",
        )
        t2 = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Salvador",
            start_date=datetime(2026, 7, 15, tzinfo=timezone.utc),
            end_date=datetime(2026, 7, 22, tzinfo=timezone.utc),
            status="upcoming",
        )
        t3 = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Paris",
            start_date=datetime(2026, 9, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 9, 10, tzinfo=timezone.utc),
            status="upcoming",
        )

        db_session.add_all([t1, t2, t3])
        await db_session.commit()

        resp = await async_client.get("/travels")
        assert resp.status_code == 200
        data = resp.json()
        assert data["count"] == 3
        destinations = [t["destination"] for t in data["travels"]]
        assert destinations == ["Salvador", "Rio de Janeiro", "Paris"]

    async def test_list_travels_filter_by_status(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /travels?status=upcoming filtra corretamente."""
        user_id = override_get_current_user.id

        t_upcoming = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Miami",
            start_date=datetime(2026, 10, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 10, 5, tzinfo=timezone.utc),
            status="upcoming",
        )
        t_completed = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Londres",
            start_date=datetime(2025, 1, 1, tzinfo=timezone.utc),
            end_date=datetime(2025, 1, 10, tzinfo=timezone.utc),
            status="completed",
        )

        db_session.add_all([t_upcoming, t_completed])
        await db_session.commit()

        resp = await async_client.get("/travels?status=upcoming")
        assert resp.status_code == 200
        data = resp.json()
        assert data["count"] == 1
        assert data["travels"][0]["destination"] == "Miami"
        assert data["travels"][0]["status"] == "upcoming"

    async def test_get_travel_by_id_success(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /travels/{id} retorna a viagem específica."""
        user_id = override_get_current_user.id

        travel = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Tóquio",
            start_date=datetime(2026, 12, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 12, 15, tzinfo=timezone.utc),
            status="ongoing",
            image_url="https://example.com/tokyo.jpg",
            description="Viagem de negócios",
        )
        db_session.add(travel)
        await db_session.commit()

        resp = await async_client.get(f"/travels/{travel.id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == str(travel.id)
        assert data["destination"] == "Tóquio"
        assert data["status"] == "ongoing"
        assert data["image_url"] == "https://example.com/tokyo.jpg"
        assert data["description"] == "Viagem de negócios"

    async def test_get_travel_not_found(
        self,
        async_client: AsyncClient,
    ):
        """GET /travels/{id} inexistente retorna 404."""
        fake_id = uuid.uuid4()
        resp = await async_client.get(f"/travels/{fake_id}")
        assert resp.status_code == 404
        assert resp.json()["detail"] == "Travel not found"

    async def test_get_travel_forbidden_other_user(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
    ):
        """Usuário não pode ver viagem de outro usuário."""
        other_user_id = uuid.uuid4()

        travel = TravelModel(
            id=uuid.uuid4(),
            user_id=other_user_id,
            destination="Nova York",
            start_date=datetime(2026, 11, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 11, 10, tzinfo=timezone.utc),
            status="upcoming",
        )
        db_session.add(travel)
        await db_session.commit()

        resp = await async_client.get(f"/travels/{travel.id}")
        assert resp.status_code == 404

    async def test_get_travel_invalid_id_format(
        self,
        async_client: AsyncClient,
    ):
        """GET /travels/{id} com ID mal formatado retorna 400."""
        resp = await async_client.get("/travels/invalid-uuid")
        assert resp.status_code == 400
        assert resp.json()["detail"] == "Invalid travel ID format"

    # ──────────────────────────────────────────────────────────────────
    # GET /travels/{travel_id}/documents
    # ──────────────────────────────────────────────────────────────────

    async def test_get_travel_documents_success(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /travels/{id}/documents retorna documentos com URLs assinadas."""
        user_id = override_get_current_user.id

        travel = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Barcelona",
            start_date=datetime(2026, 6, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 6, 10, tzinfo=timezone.utc),
            status="upcoming",
        )
        db_session.add(travel)
        await db_session.commit()

        doc = Documento(
            id=uuid.uuid4(),
            lead_id=uuid.uuid4(),
            travel_id=travel.id,
            nome="passagem.pdf",
            s3_key="documents/test/passagem.pdf",
            categoria="passagem",
            tamanho_bytes=2048,
            mimetype="application/pdf",
        )
        db_session.add(doc)
        await db_session.commit()

        with patch(
            "app.infrastructure.adapters.storage.s3_adapter.S3StorageAdapter.generate_presigned_url",
            return_value="https://s3.example.com/signed-passagem.pdf",
        ):
            resp = await async_client.get(f"/travels/{travel.id}/documents")

        assert resp.status_code == 200
        data = resp.json()
        assert data["count"] == 1
        assert len(data["documents"]) == 1
        assert data["documents"][0]["name"] == "passagem.pdf"
        assert data["documents"][0]["type"] == "pdf"
        assert data["documents"][0]["size_kb"] == 2
        assert data["documents"][0]["url"] == "https://s3.example.com/signed-passagem.pdf"
        assert data["documents"][0]["travel_id"] == str(travel.id)

    async def test_get_travel_documents_empty(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        """GET /travels/{id}/documents sem documentos retorna lista vazia."""
        user_id = override_get_current_user.id

        travel = TravelModel(
            id=uuid.uuid4(),
            user_id=user_id,
            destination="Lisboa",
            start_date=datetime(2026, 7, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 7, 10, tzinfo=timezone.utc),
            status="upcoming",
        )
        db_session.add(travel)
        await db_session.commit()

        resp = await async_client.get(f"/travels/{travel.id}/documents")
        assert resp.status_code == 200
        data = resp.json()
        assert data["count"] == 0
        assert data["documents"] == []

    async def test_get_travel_documents_not_found(
        self,
        async_client: AsyncClient,
    ):
        """GET /travels/{id}/documents para viagem inexistente retorna 404."""
        fake_id = uuid.uuid4()
        resp = await async_client.get(f"/travels/{fake_id}/documents")
        assert resp.status_code == 404
        assert resp.json()["detail"] == "Travel not found"

    async def test_get_travel_documents_forbidden_other_user(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
    ):
        """Usuário não pode ver documentos de viagem de outro usuário."""
        other_user_id = uuid.uuid4()

        travel = TravelModel(
            id=uuid.uuid4(),
            user_id=other_user_id,
            destination="Madri",
            start_date=datetime(2026, 8, 1, tzinfo=timezone.utc),
            end_date=datetime(2026, 8, 10, tzinfo=timezone.utc),
            status="upcoming",
        )
        db_session.add(travel)
        await db_session.commit()

        resp = await async_client.get(f"/travels/{travel.id}/documents")
        assert resp.status_code == 404

    async def test_get_travel_documents_invalid_id_format(
        self,
        async_client: AsyncClient,
    ):
        """GET /travels/{id}/documents com ID mal formatado retorna 400."""
        resp = await async_client.get("/travels/invalid-uuid/documents")
        assert resp.status_code == 400
        assert resp.json()["detail"] == "Invalid travel ID format"
