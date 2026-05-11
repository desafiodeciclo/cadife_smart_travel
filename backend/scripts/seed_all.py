"""
seed_all.py — Executa todos os seeds em ordem numérica.

Descobre automaticamente arquivos [0-9]*.py em scripts/db/seeds/ e chama
a função `run(session)` de cada um dentro de uma única sessão de banco.

Usage (from backend/ directory):
    python scripts/seed_all.py

Para rodar um seed individual:
    python scripts/db/seeds/03_briefings.py
"""
from __future__ import annotations

import asyncio
import importlib.util
import os
import sys
import time
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent   # backend/
SEEDS_DIR = Path(__file__).resolve().parent / "db" / "seeds"

for _p in [str(BACKEND_DIR), str(SEEDS_DIR)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from app.infrastructure.persistence.database import AsyncSessionLocal, engine


def _load(seed_file: Path):
    spec = importlib.util.spec_from_file_location(seed_file.stem, seed_file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


async def main() -> None:
    seed_files = sorted(SEEDS_DIR.glob("[0-9]*.py"))

    if not seed_files:
        print(f"[WARN] Nenhum seed encontrado em {SEEDS_DIR}")
        return

    print("=" * 55)
    print("  Cadife Smart Travel — Full Database Seed")
    print("=" * 55)
    print(f"  {len(seed_files)} seed(s) encontrado(s)\n")

    total_start = time.perf_counter()

    async with AsyncSessionLocal() as session:
        for seed_file in seed_files:
            label = seed_file.name
            print(f"▶  {label}")
            t0 = time.perf_counter()
            module = _load(seed_file)
            await module.run(session)
            elapsed = time.perf_counter() - t0
            print(f"   ✓ {label} ({elapsed:.2f}s)\n")

    await engine.dispose()

    total = time.perf_counter() - total_start
    print("=" * 55)
    print(f"  [DONE] Todos os seeds concluídos em {total:.2f}s")
    print("=" * 55)
    print()
    print("Credenciais demo:")
    print("  admin@cadifetoure.com.br          → Admin")
    print("  daniela.costa@cadifetoure.com.br  → Consultora")
    print("  otavio.grotto@gmail.com           → Cliente (Paris, fechado)")
    print("  camila.santos@gmail.com           → Cliente (Tóquio, proposta)")
    print("  rafael.mendes@gmail.com           → Cliente (Nova York, agendado)")
    print("  Senha de todos: Cadife@2026")


if __name__ == "__main__":
    asyncio.run(main())
