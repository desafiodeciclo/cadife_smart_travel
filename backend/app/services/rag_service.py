import os
from pathlib import Path
from typing import Optional

import structlog
from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_openai import OpenAIEmbeddings
from pydantic import SecretStr

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

KNOWLEDGE_BASE_DIR = Path(__file__).parent.parent.parent / "knowledge_base"

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=400,
    chunk_overlap=50,
    length_function=len,
    separators=["\n\n", "\n", ". ", " ", ""],
)

_vectorstore: Optional[Chroma] = None


def _load_documents() -> list[Document]:
    documents: list[Document] = []
    if not KNOWLEDGE_BASE_DIR.exists():
        logger.warning("knowledge_base_dir_missing", path=str(KNOWLEDGE_BASE_DIR))
        return documents

    for filename in os.listdir(KNOWLEDGE_BASE_DIR):
        if not filename.endswith(".txt"):
            continue
        filepath = KNOWLEDGE_BASE_DIR / filename
        content = filepath.read_text(encoding="utf-8")
        chunks = text_splitter.split_text(content)
        for i, chunk in enumerate(chunks):
            documents.append(Document(
                page_content=chunk,
                metadata={"source": filename, "chunk_index": i},
            ))
    logger.info("knowledge_base_loaded", total_chunks=len(documents))
    return documents


def get_vectorstore() -> Chroma:
    global _vectorstore
    if _vectorstore is None:
        embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small",
            api_key=SecretStr(settings.OPENAI_API_KEY),
        )
        persist_dir = settings.CHROMA_PERSIST_DIR

        if os.path.exists(persist_dir) and os.listdir(persist_dir):
            _vectorstore = Chroma(
                persist_directory=persist_dir,
                embedding_function=embeddings,
            )
            logger.info("vectorstore_loaded_from_disk", path=persist_dir)
        else:
            documents = _load_documents()
            _vectorstore = Chroma.from_documents(
                documents,
                embeddings,
                persist_directory=persist_dir,
            )
            logger.info("vectorstore_created", path=persist_dir)

    return _vectorstore


def get_rag_document_count() -> int:
    try:
        vs = get_vectorstore()
        return vs._collection.count()
    except Exception:
        return 0
