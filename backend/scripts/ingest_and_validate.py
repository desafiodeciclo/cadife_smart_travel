"""
RAG Knowledge Base — Ingestion + Semantic Validation
======================================================
Script para popular o ChromaDB com os documentos da Cadife Tour e validar
a qualidade do retrieval via 10 queries semânticas predefinidas.

Uso:
    cd backend
    python scripts/ingest_and_validate.py

Requer:
    - OPENAI_API_KEY configurada no .env
    - Documentos .txt em ./knowledge_base/
"""
import asyncio
import json
import sys
from pathlib import Path

# Adiciona o diretório pai (backend) ao path para imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.services.ingestion_pipeline import get_ingestion_pipeline
from app.services.rag_service import get_vectorstore, retrieve_context, retrieve_with_metadata_filter

# ---------------------------------------------------------------------------
# 10 Queries de Validação Semântica (Critérios de Aceite MVP — Seção 14.1)
# ---------------------------------------------------------------------------

VALIDATION_QUERIES = [
    {
        "id": 1,
        "query": "Qual é a missão da Cadife Tour?",
        "expected_sources": ["identidade_empresa.txt"],
        "tema": "Identidade",
    },
    {
        "id": 2,
        "query": "Como funciona o fluxo de atendimento da Cadife?",
        "expected_sources": ["fluxo_atendimento.txt", "regras_negocio.txt"],
        "tema": "Processo",
    },
    {
        "id": 3,
        "query": "Preciso de passaporte para viajar para o exterior?",
        "expected_sources": ["faq.txt"],
        "tema": "Documentação",
    },
    {
        "id": 4,
        "query": "Quais são as regras de qualificação de leads?",
        "expected_sources": ["regras_negocio.txt", "fluxo_atendimento.txt"],
        "tema": "Regras",
    },
    {
        "id": 5,
        "query": "Quais destinos a Cadife oferece na Europa?",
        "expected_sources": ["destinos.txt"],
        "tema": "Destinos",
    },
    {
        "id": 6,
        "query": "Como responder quando o cliente acha caro?",
        "expected_sources": ["objecoes.txt", "argumentacao.txt"],
        "tema": "Vendas",
    },
    {
        "id": 7,
        "query": "Qual é a proposta de valor da Cadife Tour?",
        "expected_sources": ["argumentacao.txt", "identidade_empresa.txt"],
        "tema": "Vendas",
    },
    {
        "id": 8,
        "query": "Quais os horários de atendimento dos consultores?",
        "expected_sources": ["regras_negocio.txt", "fluxo_atendimento.txt", "faq.txt"],
        "tema": "Operação",
    },
    {
        "id": 9,
        "query": "A Cadife trabalha com pacotes prontos?",
        "expected_sources": ["identidade_empresa.txt", "argumentacao.txt"],
        "tema": "Posicionamento",
    },
    {
        "id": 10,
        "query": "O que fazer quando o cliente não responde mais?",
        "expected_sources": ["objecoes.txt", "fluxo_atendimento.txt"],
        "tema": "Follow-up",
    },
]


def _evaluate_query(vs, q: dict, k: int = 4) -> dict:
    """
    Executa a query no vectorstore e avalia relevância com base nos metadados
    'source' dos chunks recuperados.
    """
    docs = vs.similarity_search(q["query"], k=k)
    retrieved_sources = [d.metadata.get("source", "unknown") for d in docs]

    # Calcula acertos: quantos dos expected_sources apareceram nos top-k?
    hits = [src for src in retrieved_sources if src in q["expected_sources"]]
    hit_rate = len(hits) / k  # proporção de chunks relevantes nos top-k

    # Flag de sucesso: pelo menos 1 chunk relevante nos top-k
    success = any(src in q["expected_sources"] for src in retrieved_sources)

    return {
        "id": q["id"],
        "query": q["query"],
        "expected_sources": q["expected_sources"],
        "retrieved_sources": retrieved_sources,
        "hit_rate": round(hit_rate, 2),
        "success": success,
        "tema": q["tema"],
    }


async def main():
    print("=" * 70)
    print("CADIFE TOUR — RAG Knowledge Base Ingestion & Validation")
    print("=" * 70)

    # ------------------------------------------------------------------
    # 1. Ingestão
    # ------------------------------------------------------------------
    print("\n[1/3] Executando pipeline de ingestão...")
    pipeline = get_ingestion_pipeline()
    result = await pipeline.ingest_all(force=True)
    print(f"       Status: {result['status']}")
    print(f"       Processados: {result['processed']}")
    print(f"       Skipped: {result['skipped']}")
    print(f"       Failed: {result['failed']}")
    print(f"       Removidos: {result['removed']}")

    if result.get("status") != "ok":
        print("\n[ERRO] Ingestão falhou. Verifique os logs.")
        sys.exit(1)

    # ------------------------------------------------------------------
    # 2. Estatísticas do VectorStore
    # ------------------------------------------------------------------
    print("\n[2/3] Estatísticas do VectorStore:")
    vs = get_vectorstore()
    count = vs._collection.count()
    print(f"       Total de chunks indexados: {count}")

    status = pipeline.get_status()
    print(f"       Documentos no cache: {status['indexed_documents']}")
    print(f"       Total chunks no cache: {status['total_chunks']}")
    for doc in status["documents"]:
        print(f"         - {doc['filename']}: {doc['chunk_count']} chunks")

    # ------------------------------------------------------------------
    # 3. Validação Semântica
    # ------------------------------------------------------------------
    print("\n[3/3] Rodando 10 queries de validação semântica...")
    results = []
    for q in VALIDATION_QUERIES:
        eval_result = _evaluate_query(vs, q, k=4)
        results.append(eval_result)

    # Resumo
    successes = sum(1 for r in results if r["success"])
    avg_hit_rate = sum(r["hit_rate"] for r in results) / len(results)

    print(f"\n       Resultado Geral:")
    print(f"       - Queries com sucesso (≥1 chunk relevante): {successes}/{len(results)}")
    print(f"       - Taxa média de relevância (hit rate): {avg_hit_rate:.2%}")

    print(f"\n       Detalhamento por Query:")
    for r in results:
        status_icon = "✅" if r["success"] else "❌"
        print(f"       {status_icon} Q{r['id']:02d} [{r['tema']}] hit_rate={r['hit_rate']:.2f} | {r['query']}")
        print(f"          Esperado: {r['expected_sources']}")
        print(f"          Recuperado: {r['retrieved_sources']}")

    # ------------------------------------------------------------------
    # 4. Critério de Aceite
    # ------------------------------------------------------------------
    print("\n" + "=" * 70)
    if successes >= 8 and avg_hit_rate >= 0.4:
        print("RESULTADO: PASSOU nos critérios de aceite MVP (≥8/10 queries com sucesso)")
    else:
        print("RESULTADO: NÃO PASSOU — ajuste de chunking/overlap recomendado")
    print("=" * 70)

    # Salva relatório JSON
    report_path = Path("./validation_report.json")
    report = {
        "ingestion": result,
        "vectorstore_stats": status,
        "validation": {
            "total_queries": len(results),
            "successes": successes,
            "avg_hit_rate": round(avg_hit_rate, 4),
            "queries": results,
        },
    }
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nRelatório salvo em: {report_path.resolve()}")


if __name__ == "__main__":
    asyncio.run(main())
