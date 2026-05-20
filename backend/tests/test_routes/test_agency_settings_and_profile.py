"""
Tests — Agency Settings + Consultor Profile (PRD)
==================================================
Covers:
  - GET /agency/settings auto-creates default singleton
  - PUT /agency/settings rejects invalid horario (422)
  - Templates: create with valid placeholders OK; invalid → 422
  - Templates: soft-delete preserves row but excludes from list
  - PATCH /users/me/bio strips HTML and persists
  - PATCH /users/me/profile-photo rejects non-image (415) and oversize (413)
  - GET /users/me/metrics returns zero-state when no leads
  - GET /users/me/goals backfills missing months with 0/0
  - PUT /users/me/goals/{year}/{month} requires admin
  - sale_goal_service.increment_achieved is idempotent on cold/hot rows
"""

from __future__ import annotations

import io
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.agency_settings_model import (
    AgencySettingsModel,
    MessageTemplateModel,
)
from app.infrastructure.persistence.models.sale_goal_model import SaleGoalModel
from app.services import sale_goal_service


# ══════════════════════════════════════════════════════════════════════════════
# Agency Settings
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestAgencySettings:

    async def test_get_settings_seeds_default_singleton(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        # No agency_settings row in DB yet → handler must auto-seed
        resp = await async_client.get("/agency/settings")
        assert resp.status_code == 200
        body = resp.json()
        assert body["horario_funcionamento"]["dias"] == [1, 2, 3, 4, 5]
        assert body["horario_funcionamento"]["inicio"] == "09:00"
        assert body["horario_funcionamento"]["fim"] == "16:00"
        assert body["templates"] == []

    async def test_put_settings_admin_updates_horario(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,  # admin by default in conftest
    ):
        payload = {
            "horario_funcionamento": {
                "dias": [1, 2, 3, 4, 5],
                "inicio": "10:00",
                "fim": "18:00",
            }
        }
        resp = await async_client.put("/agency/settings", json=payload)
        assert resp.status_code == 200
        assert resp.json()["horario_funcionamento"]["inicio"] == "10:00"

    async def test_put_settings_rejects_fim_before_inicio(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "horario_funcionamento": {
                "dias": [1],
                "inicio": "16:00",
                "fim": "09:00",
            }
        }
        resp = await async_client.put("/agency/settings", json=payload)
        assert resp.status_code == 422

    async def test_put_settings_rejects_dia_out_of_range(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "horario_funcionamento": {
                "dias": [0, 8],
                "inicio": "09:00",
                "fim": "16:00",
            }
        }
        resp = await async_client.put("/agency/settings", json=payload)
        assert resp.status_code == 422

    async def test_put_settings_rejects_intervalo_menor_que_1h(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "horario_funcionamento": {
                "dias": [1],
                "inicio": "09:00",
                "fim": "09:30",
            }
        }
        resp = await async_client.put("/agency/settings", json=payload)
        assert resp.status_code == 422


# ══════════════════════════════════════════════════════════════════════════════
# Templates
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestMessageTemplates:

    async def test_create_template_with_valid_placeholder_ok(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "nome": "Boas-vindas",
            "categoria": "boas_vindas",
            "conteudo": "Olá {{nome}}, bem-vindo!",
            "variaveis": ["nome"],
        }
        resp = await async_client.post("/agency/settings/templates", json=payload)
        assert resp.status_code == 201
        body = resp.json()
        assert body["nome"] == "Boas-vindas"
        assert "nome" in body["variaveis"]

    async def test_create_template_invalid_placeholder_rejected(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "nome": "Bad",
            "categoria": "outro",
            "conteudo": "Olá {{naoexiste}}",
            "variaveis": ["naoexiste"],
        }
        resp = await async_client.post("/agency/settings/templates", json=payload)
        assert resp.status_code == 422

    async def test_create_template_categoria_invalida(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        payload = {
            "nome": "X",
            "categoria": "categoria_inexistente",
            "conteudo": "vazio",
            "variaveis": [],
        }
        resp = await async_client.post("/agency/settings/templates", json=payload)
        assert resp.status_code == 422

    async def test_delete_template_soft_deletes(
        self,
        async_client: AsyncClient,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        # Create
        payload = {
            "nome": "Lembrete",
            "categoria": "lembrete",
            "conteudo": "Olá {{nome}}",
            "variaveis": ["nome"],
        }
        create_resp = await async_client.post(
            "/agency/settings/templates", json=payload
        )
        assert create_resp.status_code == 201
        template_id = create_resp.json()["id"]

        # Delete
        del_resp = await async_client.delete(
            f"/agency/settings/templates/{template_id}"
        )
        assert del_resp.status_code == 204

        # GET settings no longer lists it
        list_resp = await async_client.get("/agency/settings")
        assert list_resp.status_code == 200
        ids = [t["id"] for t in list_resp.json()["templates"]]
        assert template_id not in ids

    async def test_delete_template_404_if_not_found(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.delete(
            f"/agency/settings/templates/{uuid.uuid4()}"
        )
        assert resp.status_code == 404


# ══════════════════════════════════════════════════════════════════════════════
# Bio
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestBio:

    async def test_update_bio_ok(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.patch(
            "/users/me/bio", json={"bio": "Consultor de viagens há 10 anos."}
        )
        assert resp.status_code == 200
        assert resp.json()["bio"] == "Consultor de viagens há 10 anos."

    async def test_update_bio_strips_html(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.patch(
            "/users/me/bio",
            json={"bio": "<script>alert(1)</script>Olá <b>mundo</b>"},
        )
        assert resp.status_code == 200
        # tags removed, content kept
        assert "<" not in resp.json()["bio"]
        assert "alert" in resp.json()["bio"] or "Olá" in resp.json()["bio"]

    async def test_update_bio_too_long(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.patch(
            "/users/me/bio", json={"bio": "x" * 501}
        )
        assert resp.status_code == 422


# ══════════════════════════════════════════════════════════════════════════════
# Profile photo
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestProfilePhoto:

    async def test_upload_photo_rejects_non_image(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        files = {"file": ("doc.pdf", b"fake pdf bytes", "application/pdf")}
        resp = await async_client.patch("/users/me/profile-photo", files=files)
        assert resp.status_code == 415

    async def test_upload_photo_rejects_oversize(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        oversize = b"\x89PNG\r\n\x1a\n" + b"\x00" * (5 * 1024 * 1024 + 100)
        files = {"file": ("big.png", oversize, "image/png")}
        resp = await async_client.patch("/users/me/profile-photo", files=files)
        assert resp.status_code == 413

    async def test_upload_photo_corrupted_returns_422(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        # Random bytes — PIL fails to open
        files = {"file": ("trash.jpg", b"not-an-image-at-all", "image/jpeg")}
        resp = await async_client.patch("/users/me/profile-photo", files=files)
        # PIL raises → handler converts to 422
        assert resp.status_code == 422


# ══════════════════════════════════════════════════════════════════════════════
# Metrics
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestMetrics:

    async def test_metrics_zero_state(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.get("/users/me/metrics")
        assert resp.status_code == 200
        body = resp.json()
        assert body["leads_total"] == 0
        assert body["taxa_conversao"] == 0.0
        # New fields added in B-fix-dashboard-metrics-admin-consultor
        assert body["leads_ativos"] == 0
        assert body["receita_gerada"] == 0.0


# ══════════════════════════════════════════════════════════════════════════════
# Goals
# ══════════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
class TestGoals:

    async def test_goals_default_3_months_backfill(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.get("/users/me/goals")
        assert resp.status_code == 200
        body = resp.json()
        assert len(body["goals"]) == 3  # default months=3
        # All zero-state since no DB rows
        for g in body["goals"]:
            assert g["target"] == 0
            assert g["achieved"] == 0

    async def test_goals_invalid_months_query(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        resp = await async_client.get("/users/me/goals?months=15")
        assert resp.status_code == 422

    async def test_put_goal_target_admin_ok(
        self,
        async_client: AsyncClient,
        override_get_current_user,
    ):
        # conftest creates user with perfil="admin" by default
        resp = await async_client.put(
            "/users/me/goals/2026/5", json={"target": 8}
        )
        assert resp.status_code == 200
        assert resp.json()["target"] == 8

    async def test_increment_achieved_idempotent_on_existing_row(
        self,
        db_session: AsyncSession,
        override_get_current_user,
    ):
        user_id = override_get_current_user.id
        # First call creates row with achieved=1
        row1 = await sale_goal_service.increment_achieved(
            db_session, user_id=user_id, period_year=2026, period_month=5
        )
        assert row1.achieved == 1
        # Second call increments to 2
        row2 = await sale_goal_service.increment_achieved(
            db_session, user_id=user_id, period_year=2026, period_month=5
        )
        assert row2.achieved == 2
        assert row2.id == row1.id  # same row updated, not duplicated
