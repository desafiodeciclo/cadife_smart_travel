"""
run_all_seeds.py — Orquestrador de seeds. Executa todos os módulos 00–11 em ordem.

Uso:
    cd backend
    python scripts/db/seeds/run_all_seeds.py

Flags:
    --only 00 01 03   executa somente os módulos listados
    --skip 10 11      pula os módulos listados

Cada módulo é idempotente (usa upsert/skip), seguro rodar múltiplas vezes.
"""
from __future__ import annotations

import argparse
import asyncio
import importlib.util
import sys
import time
from pathlib import Path

# ── path setup ────────────────────────────────────────────────────────────────
_BACKEND = Path(__file__).resolve().parents[3]  # seeds/ → db/ → scripts/ → backend/
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from app.infrastructure.persistence.database import AsyncSessionLocal, engine  # noqa: E402

# ── seed modules (order matters — FK dependencies) ───────────────────────────
_MODULES = [
    "00_admin",
    "01_users",
    "02_leads",
    "03_briefings",
    "04_agendamentos",
    "05_propostas",
    "06_interacoes",
    "07_suitcase",
    "08_documentos",
    "09_offers",
    "10_travel_diary",
    "11_itinerary",
]


def _load_module(name: str):
    path = _SEEDS / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


async def _main(only: list[str] | None, skip: list[str] | None) -> None:
    to_run = _MODULES[:]
    if only:
        prefixes = set(only)
        to_run = [m for m in _MODULES if any(m.startswith(p) for p in prefixes)]
    if skip:
        prefixes = set(skip)
        to_run = [m for m in to_run if not any(m.startswith(p) for p in prefixes)]

    if not to_run:
        print("[WARN] Nenhum módulo selecionado.")
        return

    print(f"\n{'='*55}")
    print(f"  Cadife Smart Travel — Seeds ({len(to_run)} módulos)")
    print(f"{'='*55}\n")

    async with AsyncSessionLocal() as session:
        for name in to_run:
            t0 = time.monotonic()
            print(f"── {name} ─────────────────────────────────────")
            try:
                mod = _load_module(name)
                await mod.run(session)
            except Exception as exc:
                print(f"  [ERROR] {exc}")
                raise
            elapsed = time.monotonic() - t0
            print(f"  ✓ concluído em {elapsed:.2f}s\n")

    await engine.dispose()
    print(f"{'='*55}")
    print("  Todos os seeds concluídos com sucesso.")
    print(f"{'='*55}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Executa os seeds do banco de dados.")
    parser.add_argument(
        "--only",
        nargs="+",
        metavar="PREFIX",
        help="Executa somente os módulos com esses prefixos (ex: 00 01 09)",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        metavar="PREFIX",
        help="Pula os módulos com esses prefixos",
    )
    args = parser.parse_args()
    asyncio.run(_main(only=args.only, skip=args.skip))
