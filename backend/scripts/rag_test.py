"""
RAG Test CLI — Perguntas em tempo real (usa ChromaDB ja indexado)
==================================================================
Conecta direto no ChromaDB que o backend acabou de criar.
Nao precisa de JWT, nao precisa do backend rodando.

Uso:
    cd backend
    python scripts/rag_test.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from langchain_chroma import Chroma
from langchain_google_genai import GoogleGenerativeAIEmbeddings

from app.core.config import get_settings

settings = get_settings()
CHROMA_PERSIST_DIR = Path("./chroma_db")


def main():
    print("=" * 70)
    print("  CADIFE TOUR — RAG TEST (Gemini Embeddings)")
    print("  Conectando ao ChromaDB existente...")
    print("=" * 70)

    if not settings.GEMINI_API_KEY:
        print("[ERRO] GEMINI_API_KEY nao encontrada no .env")
        sys.exit(1)

    if not CHROMA_PERSIST_DIR.exists():
        print(f"[ERRO] ChromaDB nao encontrado em: {CHROMA_PERSIST_DIR}")
        print("       Rode a reindexacao primeiro:")
        print("       python -c \"import asyncio; from app.services.ingestion_pipeline import get_ingestion_pipeline; asyncio.run(get_ingestion_pipeline().ingest_all(force=True))\"")
        sys.exit(1)

    embeddings = GoogleGenerativeAIEmbeddings(
        model="models/gemini-embedding-001",
        google_api_key=settings.GEMINI_API_KEY,
    )

    vs = Chroma(
        persist_directory=str(CHROMA_PERSIST_DIR),
        embedding_function=embeddings,
    )

    count = vs._collection.count()
    print(f"[OK] {count} chunks carregados do ChromaDB")
    print("\n  Comandos:")
    print("    /quit  — Sai")
    print("=" * 70)

    while True:
        try:
            question = input("\n> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n[QUIT] Ate mais!")
            break

        if not question:
            continue

        if question.lower() in ("/quit", "exit", "sair"):
            print("[QUIT] Ate mais!")
            break

        # Busca os 3 chunks mais relevantes
        docs = vs.similarity_search(question, k=3)

        if not docs:
            print("   [RESPOSTA] Nenhum documento encontrado.")
            continue

        print(f"\n   [TOP {len(docs)} RESULTADOS]")
        for i, doc in enumerate(docs, 1):
            source = doc.metadata.get("source", "unknown")
            preview = doc.page_content.replace("\n", " ").strip()
            if len(preview) > 600:
                preview = preview[:600] + "..."
            print(f"\n   --- Resultado {i} (fonte: {source}) ---")
            print(f"   {preview}")


if __name__ == "__main__":
    main()
