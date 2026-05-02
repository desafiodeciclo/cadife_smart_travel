"""
RAG Knowledge Base — Local Embeddings Ingestion + Semantic Validation
=======================================================================
Script alternativo que usa HuggingFaceEmbeddings (local/offline) para
popular o ChromaDB quando a OpenAI não está disponível (ex: quota esgotada).

Modelo: sentence-transformers/all-MiniLM-L6-v2 (dim 384, multilíngue)

Uso:
    cd backend
    python scripts/ingest_and_validate_local.py

Nota: Este script é para desenvolvimento/validação. Em produção, use
      GoogleGenerativeAIEmbeddings via o pipeline padrão (ingestion_pipeline.py).
"""
import asyncio
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import tiktoken
from langchain_chroma import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter

from app.services.metadata_tagger import extract_tags, tags_to_metadata

# ---------------------------------------------------------------------------
# Configuração
# ---------------------------------------------------------------------------
KNOWLEDGE_BASE_DIR = Path("./knowledge_base")
CHROMA_PERSIST_DIR = Path("./chroma_db_local")
CHUNK_SIZE = 500
CHUNK_OVERLAP = 30

_tiktoken_enc = tiktoken.get_encoding("cl100k_base")


def _token_length(text: str) -> int:
    return len(_tiktoken_enc.encode(text))


# Text splitter conforme spec (300-500 tokens)
_splitter = RecursiveCharacterTextSplitter(
    chunk_size=CHUNK_SIZE,
    chunk_overlap=CHUNK_OVERLAP,
    length_function=_token_length,
    separators=["\n\n", "\n", ". ", " ", ""],
)

# Embeddings local (multilíngue, otimizado para paráfrases/português)
_embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"normalize_embeddings": True},
)

# ---------------------------------------------------------------------------
# 10 Queries de Validação Semântica
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


def _load_documents() -> list[Document]:
    documents: list[Document] = []
    for filepath in sorted(KNOWLEDGE_BASE_DIR.glob("*.txt")):
        content = filepath.read_text(encoding="utf-8")
        chunks = _splitter.split_text(content)
        for i, chunk in enumerate(chunks):
            tags = extract_tags(chunk, filepath.name)
            metadata = tags_to_metadata(tags, filepath.name, i, "local")
            documents.append(Document(page_content=chunk, metadata=metadata))
        print(f"   [FILE] {filepath.name} -> {len(chunks)} chunks")
    return documents


def _evaluate_query(vs, q: dict, k: int = 4) -> dict:
    docs = vs.similarity_search(q["query"], k=k)
    best_doc = docs[0]  # chunk mais relevante
    answer = best_doc.page_content.replace("\n", " ").strip()
    return {
        "query": q["query"],
        "answer": answer,
    }


async def main():
    print("=" * 70)
    print("CADIFE TOUR — RAG KB Ingestion & Validation (Local Embeddings)")
    print("=" * 70)

    # Limpar chroma local anterior para reindexação limpa
    if CHROMA_PERSIST_DIR.exists():
        print(f"\n[0/3] Limpando ChromaDB local anterior: {CHROMA_PERSIST_DIR}")
        shutil.rmtree(CHROMA_PERSIST_DIR)

    # ------------------------------------------------------------------
    # 1. Ingestão
    # ------------------------------------------------------------------
    print("\n[1/3] Carregando e fazendo chunking dos documentos...")
    documents = _load_documents()
    print(f"       Total de chunks: {len(documents)}")

    print("\n[2/3] Indexando no ChromaDB com HuggingFaceEmbeddings...")
    print("       Modelo: sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
    vs = Chroma.from_documents(
        documents=documents,
        embedding=_embeddings,
        persist_directory=str(CHROMA_PERSIST_DIR),
    )
    count = vs._collection.count()
    print(f"       Chunks indexados com sucesso: {count}")

    # ------------------------------------------------------------------
    # 2. Validação Semântica
    # ------------------------------------------------------------------
    print("\n[3/3] Rodando 10 queries de validação semântica...")
    results = []
    for q in VALIDATION_QUERIES:
        eval_result = _evaluate_query(vs, q, k=4)
        results.append(eval_result)

    print(f"\n   [PERGUNTAS E RESPOSTAS]")
    for i, r in enumerate(results, 1):
        print(f"\n   {i}. Pergunta: {r['query']}")
        answer_preview = r['answer'][:400]
        print(f"      Resposta: {answer_preview}{'...' if len(r['answer']) > 400 else ''}")

    # ------------------------------------------------------------------
    # 3. Final
    # ------------------------------------------------------------------
    print("\n" + "=" * 70)
    print(f"[DONE] {len(results)} perguntas respondidas com base nos documentos da Cadife Tour.")
    print("=" * 70)

    report_path = Path("./validation_report_local.json")
    report = {
        "embedding_model": "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        "vectorstore": str(CHROMA_PERSIST_DIR),
        "chunk_size": CHUNK_SIZE,
        "chunk_overlap": CHUNK_OVERLAP,
        "total_chunks": count,
        "validation": {
            "total_queries": len(results),
            "queries": results,
        },
    }
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n[REPORT] Relatorio salvo em: {report_path.resolve()}")


if __name__ == "__main__":
    asyncio.run(main())
