"""
Conftest for test_use_cases — stubs heavy optional dependencies (langchain,
firebase_admin) that are not installed in CI / local venv but are imported
transitively when loading process_whatsapp_message.
"""
import sys
import types
from unittest.mock import MagicMock


class _AutoStubModule(types.ModuleType):
    """Module stub that returns a MagicMock for any attribute access."""

    def __getattr__(self, name: str):
        value = MagicMock()
        setattr(self, name, value)
        return value


def _stub(name: str) -> None:
    if name not in sys.modules:
        sys.modules[name] = _AutoStubModule(name)


for _mod in [
    # langchain core + submodules used by ai_service / rag_service
    "langchain",
    "langchain.memory",
    "langchain.output_parsers",
    "langchain.prompts",
    "langchain.schema",
    "langchain.text_splitter",
    "langchain.chains",
    "langchain.chat_models",
    "langchain_google_genai",
    "langchain_community",
    "langchain_community.vectorstores",
    "langchain_chroma",
    "langchain_text_splitters",
    "langchain_core",
    "langchain_core.documents",
    "langchain_core.embeddings",
    "langchain_core.messages",
    "langchain_core.prompts",
    "langchain_core.runnables",
    "langgraph",
    "langgraph.graph",
    # firebase_admin used by fcm_service
    "firebase_admin",
    "firebase_admin.messaging",
    "firebase_admin.credentials",
]:
    _stub(_mod)
