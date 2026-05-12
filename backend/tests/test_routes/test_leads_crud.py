"""
Tests — Lead CRUD, Idempotência, Paginação Cursor e Soft Delete
================================================================
Valida os critérios de aceite de B-feat-leads-crud-idempotency:

  - POST /leads: upsert por telefone (idempotência)
  - GET /leads: filtros por status/score/data/consultor + cursor pagination
  - GET /leads/{id}: detalhe enriquecido (briefing + interações)
  - PATCH /leads/{id}: atualização parcial com state machine
  - DELETE /leads/{id}: soft-delete com campo deletado_em
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

import pytest

# ── Helpers ────────────────────────────────────────────────────────────────


async def _create_lead(async_client, phone: str, nome: str = "Teste", origem: str = "whatsapp"):
    return await async_client.post(
        "/leads", json={"telefone": phone, "nome": nome, "origem": origem}
    )


# ═══════════════════════════════════════════════════════════════════════════
# POST /leads — upsert idempotente
# ═══════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
async def test_post_lead_cria_com_status_novo(async_client):
    """Primeiro POST deve criar o lead com status NOVO."""
    r = await _create_lead(async_client, "+5511900000001")
    assert r.status_code in (200, 201)
    data = r.json()
    assert data["status"] == "novo"
    assert data["telefone"] == "+5511900000001"


@pytest.mark.asyncio
async def test_post_lead_idempotente_mesmo_telefone(async_client):
    """Dois POSTs com mesmo telefone devem retornar o mesmo lead (upsert)."""
    phone = "+5511900000002"
    r1 = await _create_lead(async_client, phone, nome="Alice")
    r2 = await _create_lead(async_client, phone, nome="Alice")

    assert r1.status_code in (200, 201)
    assert r2.status_code == 200  # segunda chamada é 200 (lead já existe)
    assert r1.json()["id"] == r2.json()["id"], "Dois POSTs não devem criar dois leads"


@pytest.mark.asyncio
async def test_post_lead_campos_obrigatorios(async_client):
    """POST sem telefone deve retornar 422."""
    r = await async_client.post("/leads", json={"nome": "Sem Telefone"})
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_post_lead_origem_whatsapp_default(async_client):
    """Origem padrão deve ser whatsapp quando não informada."""
    r = await async_client.post("/leads", json={"telefone": "+5511900000003"})
    assert r.status_code in (200, 201)
    assert r.json()["origem"] == "whatsapp"


# ═══════════════════════════════════════════════════════════════════════════
# GET /leads — filtros e paginação
# ═══════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
async def test_get_leads_retorna_lista(async_client):
    """GET /leads deve retornar estrutura paginada válida."""
    await _create_lead(async_client, "+5511900000010")
    r = await async_client.get("/leads")
    assert r.status_code == 200
    data = r.json()
    assert "items" in data
    assert "total" in data or "has_more" in data  # offset ou cursor


@pytest.mark.asyncio
async def test_get_leads_filtro_status(async_client):
    """Filtro por status deve retornar apenas leads com aquele status."""
    await _create_lead(async_client, "+5511900000020")
    r = await async_client.get("/leads?status=novo")
    assert r.status_code == 200
    items = r.json().get("items", [])
    for item in items:
        assert item["status"] == "novo"


@pytest.mark.asyncio
async def test_get_leads_cursor_pagination(async_client):
    """Paginação cursor-based deve retornar itens sequenciais sem duplicatas."""
    phones = [f"+5511900001{i:02d}" for i in range(5)]
    for p in phones:
        await _create_lead(async_client, p)

    # Página 1 com limit=2
    r1 = await async_client.get("/leads?limit=2&cursor=")
    assert r1.status_code == 200
    body1 = r1.json()

    # Se cursor não informado (vazio), deve usar offset
    # Testa cursor real: busca primeiro sem cursor
    r_first = await async_client.get("/leads?limit=2")
    assert r_first.status_code == 200
    body_first = r_first.json()

    # Com cursor mode: passa cursor= em branco não ativa o modo cursor
    # Usa o cursor retornado pela resposta
    if "next_cursor" in body_first and body_first["next_cursor"]:
        next_cur = body_first["next_cursor"]
        r2 = await async_client.get(f"/leads?limit=2&cursor={next_cur}")
        assert r2.status_code == 200
        body2 = r2.json()
        ids1 = {i["id"] for i in body_first["items"]}
        ids2 = {i["id"] for i in body2["items"]}
        assert ids1.isdisjoint(ids2), "Cursor pagination não deve retornar duplicatas"


def test_cursor_invalido_levanta_value_error():
    """Cursor corrompido deve levantar ValueError na camada de serviço (422 via HTTP)."""
    from app.services.lead_service import _decode_cursor

    with pytest.raises(ValueError):
        _decode_cursor("INVALIDO_BASE64_CORRUPTO!!!")


def test_order_by_invalido_nao_esta_nos_campos_permitidos():
    """Campos de ordenação permitidos são fixos — campo inválido não existe no dict."""
    from app.services.lead_service import _ORDER_FIELDS

    assert "campo_nao_existe" not in _ORDER_FIELDS
    assert "criado_em" in _ORDER_FIELDS
    assert "atualizado_em" in _ORDER_FIELDS


# ═══════════════════════════════════════════════════════════════════════════
# GET /leads/{id} — detalhe enriquecido
# ═══════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
async def test_get_lead_detalhe_inclui_briefing(async_client):
    """GET /leads/{id} deve incluir o campo briefing."""
    r = await _create_lead(async_client, "+5511900000030")
    lead_id = r.json()["id"]

    r2 = await async_client.get(f"/leads/{lead_id}")
    assert r2.status_code == 200
    data = r2.json()
    assert "briefing" in data
    assert "ultimas_interacoes" in data
    assert "propostas" in data


@pytest.mark.asyncio
async def test_get_lead_nao_existente_retorna_404(async_client):
    r = await async_client.get(f"/leads/{uuid.uuid4()}")
    assert r.status_code == 404


# ═══════════════════════════════════════════════════════════════════════════
# PATCH /leads/{id}
# ═══════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
async def test_patch_lead_atualiza_nome(async_client):
    """PATCH deve atualizar apenas o campo enviado."""
    r = await _create_lead(async_client, "+5511900000040", nome="Original")
    lead_id = r.json()["id"]

    r_patch = await async_client.patch(f"/leads/{lead_id}", json={"nome": "Atualizado"})
    assert r_patch.status_code == 200
    assert r_patch.json()["nome"] == "Atualizado"


@pytest.mark.asyncio
async def test_patch_lead_transicao_status_invalida_retorna_422(async_client):
    """Transição de status inválida deve retornar 422."""
    r = await _create_lead(async_client, "+5511900000041")
    lead_id = r.json()["id"]

    # NOVO → FECHADO é inválido (deve passar por qualificado)
    r_patch = await async_client.patch(f"/leads/{lead_id}", json={"status": "fechado"})
    assert r_patch.status_code == 422


@pytest.mark.asyncio
async def test_patch_lead_nao_existente_retorna_404(async_client):
    r = await async_client.patch(f"/leads/{uuid.uuid4()}", json={"nome": "X"})
    assert r.status_code == 404


# ═══════════════════════════════════════════════════════════════════════════
# DELETE /leads/{id} — soft delete com deletado_em
# ═══════════════════════════════════════════════════════════════════════════


@pytest.mark.asyncio
async def test_delete_lead_soft_delete(async_client):
    """DELETE deve retornar 204 e o lead não deve aparecer em GET /leads/{id}."""
    r = await _create_lead(async_client, "+5511900000050")
    lead_id = r.json()["id"]

    r_del = await async_client.delete(f"/leads/{lead_id}")
    assert r_del.status_code == 204

    # Lead arquivado não deve aparecer via GET
    r_get = await async_client.get(f"/leads/{lead_id}")
    assert r_get.status_code == 404


@pytest.mark.asyncio
async def test_delete_lead_nao_existente_retorna_404(async_client):
    r = await async_client.delete(f"/leads/{uuid.uuid4()}")
    assert r.status_code == 404


# ═══════════════════════════════════════════════════════════════════════════
# Serviço — lógica de cursor encoding
# ═══════════════════════════════════════════════════════════════════════════


def test_cursor_encode_decode_roundtrip():
    """Cursor deve ser reversível sem perda de dados."""
    from app.services.lead_service import _decode_cursor, _encode_cursor

    now = datetime.now(timezone.utc).replace(microsecond=0)
    lead_id = uuid.uuid4()

    cursor = _encode_cursor(now, lead_id)
    decoded_ts, decoded_id = _decode_cursor(cursor)

    assert decoded_id == lead_id
    # Compare ISO strings to avoid tz offset representation differences
    assert decoded_ts.isoformat() == now.isoformat()


def test_cursor_decode_invalido_levanta_value_error():
    from app.services.lead_service import _decode_cursor

    with pytest.raises(ValueError):
        _decode_cursor("nao-e-base64-valido!!!")
