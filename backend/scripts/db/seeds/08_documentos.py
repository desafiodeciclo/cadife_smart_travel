"""
08_documentos — Documentos de viagem por cliente.

Cobre os dados mockados em:
  - frontend_flutter/lib/features/client/home/infrastructure/mocks/client_home_mocks.dart
  - frontend_flutter/lib/features/client/documentos/data/repositories/mock_documento_repository.dart

Otávio (Paris, fechado): passagens, voucher hotel, seguro, roteiro
Camila  (Tóquio, proposta): proposta enviada, seguro, passagens
Rafael  (Nova York, agendado): proposta preliminar
"""
from __future__ import annotations

import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DocumentoCategoria
from app.models.documento import Documento
from shared import get_admin, get_lead_by_phone, get_user_by_email


# (nome, s3_key, categoria, tamanho_bytes, mimetype)
_OTAVIO_DOCS = [
    (
        "Passagens Aéreas GRU–CDG (TAM)",
        "documents/otavio-grotto/passagens-gru-cdg.pdf",
        DocumentoCategoria.passagem,
        2_621_440,
        "application/pdf",
    ),
    (
        "Voucher Hôtel Le Marais Paris",
        "documents/otavio-grotto/voucher-hotel-le-marais.pdf",
        DocumentoCategoria.voucher,
        1_258_291,
        "application/pdf",
    ),
    (
        "Seguro Viagem Internacional",
        "documents/otavio-grotto/seguro-viagem.pdf",
        DocumentoCategoria.seguro,
        838_860,
        "application/pdf",
    ),
    (
        "Roteiro Completo — Paris 7 Dias",
        "documents/otavio-grotto/roteiro-paris.pdf",
        DocumentoCategoria.itinerario,
        512_000,
        "application/pdf",
    ),
    (
        "Transfer Aeroporto CDG → Hotel",
        "documents/otavio-grotto/transfer-cdg-hotel.pdf",
        DocumentoCategoria.transfer,
        204_800,
        "application/pdf",
    ),
]

_CAMILA_DOCS = [
    (
        "Proposta Pacote Japão Explorer",
        "documents/camila-santos/proposta-japao-explorer.pdf",
        DocumentoCategoria.outros,
        1_048_576,
        "application/pdf",
    ),
    (
        "Passagens Aéreas GRU–NRT (Qatar Airways)",
        "documents/camila-santos/passagens-gru-nrt.pdf",
        DocumentoCategoria.passagem,
        2_097_152,
        "application/pdf",
    ),
    (
        "Seguro Viagem Internacional",
        "documents/camila-santos/seguro-viagem.pdf",
        DocumentoCategoria.seguro,
        838_860,
        "application/pdf",
    ),
]

_RAFAEL_DOCS = [
    (
        "Proposta Preliminar — Nova York",
        "documents/rafael-mendes/proposta-nova-york.pdf",
        DocumentoCategoria.outros,
        786_432,
        "application/pdf",
    ),
]


async def run(session: AsyncSession) -> None:
    admin = await get_admin(session)
    daniela = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    enviado_por = daniela.id if daniela else admin.id

    otavio_lead = await get_lead_by_phone(session, "+5511966666666")
    camila_lead = await get_lead_by_phone(session, "+5511955555555")
    rafael_lead = await get_lead_by_phone(session, "+5511944444444")

    batches = [
        (otavio_lead, _OTAVIO_DOCS, "Otávio (Paris)"),
        (camila_lead, _CAMILA_DOCS, "Camila (Tóquio)"),
        (rafael_lead, _RAFAEL_DOCS, "Rafael (Nova York)"),
    ]

    for lead, docs, label in batches:
        if not lead:
            print(f"  [SKIP] Lead {label} não encontrado")
            continue

        exists = await session.execute(
            select(Documento).where(Documento.lead_id == lead.id).limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Documentos {label}")
            continue

        for nome, s3_key, categoria, tamanho_bytes, mimetype in docs:
            session.add(
                Documento(
                    lead_id=lead.id,
                    nome=nome,
                    s3_key=s3_key,
                    categoria=categoria.value,
                    tamanho_bytes=tamanho_bytes,
                    mimetype=mimetype,
                    enviado_por=enviado_por,
                )
            )

        await session.commit()
        print(f"  [NEW]  {len(docs)} documento(s) → {label}")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
