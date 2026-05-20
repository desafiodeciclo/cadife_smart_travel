"""
08_documentos — Documentos de viagem por cliente.

  Otávio Grotto   (Paris, fechado)        → passagens, voucher, seguro, roteiro, transfer
  Camila Santos   (Tóquio, proposta)      → proposta, passagens, seguro
  Rafael Mendes   (Nova York, agendado)   → proposta preliminar
  Isabela Rocha   (Orlando, proposta)     → proposta, passagens, seguro
  Carla Mendonça  (Gramado, fechado)      → voucher chalé, roteiro, seguro
  Natália Costa   (Portugal+Espanha, fec) → passagens, vouchers hotel, roteiro, seguro
"""
from __future__ import annotations

import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

import uuid as _uuid

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DocumentoCategoria
from app.models.documento import Documento
from shared import get_admin, get_lead_by_phone, get_user_by_email


# (nome, s3_key, categoria, tamanho_bytes, mimetype)

_OTAVIO_DOCS = [
    ("Passagens Aéreas GRU–CDG (TAM)",             "documents/otavio-grotto/passagens-gru-cdg.pdf",     DocumentoCategoria.passagem,   2_621_440, "application/pdf"),
    ("Voucher Hôtel Le Marais Paris",               "documents/otavio-grotto/voucher-hotel-le-marais.pdf", DocumentoCategoria.voucher,  1_258_291, "application/pdf"),
    ("Seguro Viagem Internacional",                 "documents/otavio-grotto/seguro-viagem.pdf",          DocumentoCategoria.seguro,      838_860, "application/pdf"),
    ("Roteiro Completo — Paris 7 Dias",             "documents/otavio-grotto/roteiro-paris.pdf",          DocumentoCategoria.itinerario,  512_000, "application/pdf"),
    ("Transfer Aeroporto CDG → Hotel",              "documents/otavio-grotto/transfer-cdg-hotel.pdf",     DocumentoCategoria.transfer,    204_800, "application/pdf"),
]

_CAMILA_DOCS = [
    ("Proposta Pacote Japão Explorer",              "documents/camila-santos/proposta-japao-explorer.pdf", DocumentoCategoria.outros,   1_048_576, "application/pdf"),
    ("Passagens Aéreas GRU–NRT (Qatar Airways)",    "documents/camila-santos/passagens-gru-nrt.pdf",      DocumentoCategoria.passagem, 2_097_152, "application/pdf"),
    ("Seguro Viagem Internacional",                 "documents/camila-santos/seguro-viagem.pdf",          DocumentoCategoria.seguro,     838_860, "application/pdf"),
]

_RAFAEL_DOCS = [
    ("Proposta Preliminar — Nova York",             "documents/rafael-mendes/proposta-nova-york.pdf",     DocumentoCategoria.outros,     786_432, "application/pdf"),
]

_ISABELA_DOCS = [
    ("Proposta Pacote Orlando Família",             "documents/isabela-rocha/proposta-orlando-familia.pdf", DocumentoCategoria.outros, 1_310_720, "application/pdf"),
    ("Passagens Aéreas GRU–MCO (LATAM)",            "documents/isabela-rocha/passagens-gru-mco.pdf",      DocumentoCategoria.passagem, 2_359_296, "application/pdf"),
    ("Seguro Viagem Internacional",                 "documents/isabela-rocha/seguro-viagem.pdf",          DocumentoCategoria.seguro,     838_860, "application/pdf"),
    ("Park Hopper Pass — Instruções de Uso",        "documents/isabela-rocha/park-hopper-instrucoes.pdf", DocumentoCategoria.outros,     307_200, "application/pdf"),
]

_CARLA_DOCS = [
    ("Voucher Chalé Boutique — Gramado",            "documents/carla-mendonca/voucher-chale-gramado.pdf", DocumentoCategoria.voucher,    614_400, "application/pdf"),
    ("Roteiro Serra Gaúcha 5 Dias",                 "documents/carla-mendonca/roteiro-gramado.pdf",       DocumentoCategoria.itinerario, 358_400, "application/pdf"),
    ("Reserva Jantar Michelin — Gastronomia RS",    "documents/carla-mendonca/reserva-jantar.pdf",        DocumentoCategoria.outros,     204_800, "application/pdf"),
]

_NATALIA_DOCS = [
    ("Passagens Aéreas GRU–LIS–MAD–GRU (TAP)",     "documents/natalia-costa/passagens-gru-lis-mad.pdf",  DocumentoCategoria.passagem, 2_883_584, "application/pdf"),
    ("Voucher Hotel Bairro Alto — Lisboa",          "documents/natalia-costa/voucher-hotel-lisboa.pdf",   DocumentoCategoria.voucher,    819_200, "application/pdf"),
    ("Voucher Hotel Infante Sagres — Porto",        "documents/natalia-costa/voucher-hotel-porto.pdf",    DocumentoCategoria.voucher,    716_800, "application/pdf"),
    ("Voucher Hotel NH Collection — Madrid",        "documents/natalia-costa/voucher-hotel-madrid.pdf",   DocumentoCategoria.voucher,    716_800, "application/pdf"),
    ("Seguro Viagem Internacional",                 "documents/natalia-costa/seguro-viagem.pdf",          DocumentoCategoria.seguro,     838_860, "application/pdf"),
    ("Roteiro Cultural Ibérico 13 Dias",            "documents/natalia-costa/roteiro-iberico.pdf",        DocumentoCategoria.itinerario, 614_400, "application/pdf"),
]


async def run(session: AsyncSession) -> None:
    admin    = await get_admin(session)
    daniela  = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    jakeline = await get_user_by_email(session, "jakeline.lima@cadifetoure.com.br")
    bruno    = await get_user_by_email(session, "bruno.ferreira@cadifetoure.com.br")

    daniela_id  = daniela.id  if daniela  else admin.id
    jakeline_id = jakeline.id if jakeline else admin.id
    bruno_id    = bruno.id    if bruno    else admin.id

    otavio_lead  = await get_lead_by_phone(session, "+5511966666666")
    camila_lead  = await get_lead_by_phone(session, "+5511955555555")
    rafael_lead  = await get_lead_by_phone(session, "+5511944444444")
    isabela_lead = await get_lead_by_phone(session, "+5511966660003")
    carla_lead   = await get_lead_by_phone(session, "+5551933330006")
    natalia_lead = await get_lead_by_phone(session, "+5511911110008")

    batches = [
        (otavio_lead,  _OTAVIO_DOCS,  "Otávio (Paris)",            daniela_id),
        (camila_lead,  _CAMILA_DOCS,  "Camila (Tóquio)",           daniela_id),
        (rafael_lead,  _RAFAEL_DOCS,  "Rafael (Nova York)",        jakeline_id),
        (isabela_lead, _ISABELA_DOCS, "Isabela (Orlando)",         daniela_id),
        (carla_lead,   _CARLA_DOCS,   "Carla (Gramado)",           daniela_id),
        (natalia_lead, _NATALIA_DOCS, "Natália (Portugal+Espanha)",bruno_id),
    ]

    for lead, docs, label, enviado_por in batches:
        if not lead:
            print(f"  [SKIP] Lead {label} não encontrado")
            continue

        exists = await session.execute(
            select(Documento).where(Documento.lead_id == lead.id).limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Documentos {label}")
            continue

        # The DB column is documento_categoria_enum (Postgres enum) but the
        # SQLAlchemy model maps it as String(50), so asyncpg rejects the plain
        # varchar bind. We use a raw INSERT with an explicit ::documento_categoria_enum
        # cast to satisfy the strict asyncpg type system.
        for nome, s3_key, categoria, tamanho_bytes, mimetype in docs:
            await session.execute(
                text("""
                    INSERT INTO documentos (id, lead_id, nome, s3_key, categoria, tamanho_bytes, mimetype, enviado_por)
                    VALUES (CAST(:id AS uuid), CAST(:lead_id AS uuid), :nome, :s3_key,
                            CAST(:categoria AS documento_categoria_enum),
                            :tamanho, :mimetype, CAST(:enviado_por AS uuid))
                    ON CONFLICT DO NOTHING
                """),
                {
                    "id": str(_uuid.uuid4()),
                    "lead_id": str(lead.id),
                    "nome": nome,
                    "s3_key": s3_key,
                    "categoria": categoria.value,
                    "tamanho": tamanho_bytes,
                    "mimetype": mimetype,
                    "enviado_por": str(enviado_por),
                },
            )

        await session.commit()
        print(f"  [NEW]  {len(docs)} documento(s) → {label}")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
