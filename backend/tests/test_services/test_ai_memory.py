"""
Unit tests for ai_service.SimpleWindowMemory — context-window management.

Covers:
  - Buffer eviction (max 20 pairs)
  - Pending overflow queueing for summarisation
  - LLM compression integration (mocked)
  - Summary injection into load_memory_variables
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.ai_service import SimpleWindowMemory


class TestSimpleWindowMemory:
    def test_buffer_respects_max_size(self):
        mem = SimpleWindowMemory(k=3)
        for i in range(5):
            mem.save_context({"input": f"user-{i}"}, {"output": f"ai-{i}"})
        assert len(mem._buffer) == 3
        assert mem._buffer[0] == ("user-2", "ai-2")
        assert mem._buffer[-1] == ("user-4", "ai-4")

    def test_overflow_queued_for_summary(self):
        mem = SimpleWindowMemory(k=2)
        for i in range(4):
            mem.save_context({"input": f"user-{i}"}, {"output": f"ai-{i}"})
        assert len(mem._buffer) == 2
        assert len(mem._pending_for_summary) == 2
        assert mem._pending_for_summary[0] == ("user-0", "ai-0")
        assert mem._pending_for_summary[1] == ("user-1", "ai-1")

    def test_has_pending_summary(self):
        mem = SimpleWindowMemory(k=1)
        assert not mem.has_pending_summary()
        mem.save_context({"input": "a"}, {"output": "b"})
        assert not mem.has_pending_summary()  # still within k
        mem.save_context({"input": "c"}, {"output": "d"})
        assert mem.has_pending_summary()

    @pytest.mark.asyncio
    async def test_compress_pending_generates_summary(self):
        mem = SimpleWindowMemory(k=1)
        mem.save_context({"input": "Quero ir para Paris em julho"}, {"output": "Ótimo destino!"})
        mem.save_context({"input": "Somos 4 pessoas"}, {"output": "Anotado."})

        mock_response = MagicMock()
        mock_response.content = "Cliente quer Paris em julho, grupo de 4 pessoas."
        mock_chain = MagicMock()
        mock_chain.ainvoke = AsyncMock(return_value=mock_response)
        mock_prompt = MagicMock()
        mock_prompt.__or__ = MagicMock(return_value=mock_chain)

        with patch("app.services.ai_service.ChatPromptTemplate.from_messages", return_value=mock_prompt):
            await mem.compress_pending(MagicMock())

        assert not mem.has_pending_summary()
        assert "Paris em julho" in mem._summary
        assert "grupo de 4" in mem._summary

    @pytest.mark.asyncio
    async def test_compress_pending_appends_to_existing_summary(self):
        mem = SimpleWindowMemory(k=1)
        mem._summary = "Resumo anterior."
        mem.save_context({"input": "a"}, {"output": "b"})
        mem.save_context({"input": "c"}, {"output": "d"})

        mock_response = MagicMock()
        mock_response.content = "Novo trecho."
        mock_chain = MagicMock()
        mock_chain.ainvoke = AsyncMock(return_value=mock_response)
        mock_prompt = MagicMock()
        mock_prompt.__or__ = MagicMock(return_value=mock_chain)

        with patch("app.services.ai_service.ChatPromptTemplate.from_messages", return_value=mock_prompt):
            await mem.compress_pending(MagicMock())

        assert "Resumo anterior." in mem._summary
        assert "Novo trecho." in mem._summary

    def test_load_memory_variables_includes_summary(self):
        mem = SimpleWindowMemory(k=2)
        mem._summary = "Cliente quer praia no Nordeste."
        mem.save_context({"input": "Oi"}, {"output": "Olá!"})
        mem.save_context({"input": "Quero Natal"}, {"output": "Lindo destino!"})

        result = mem.load_memory_variables({})
        messages = result["chat_history"]

        assert messages[0]["role"] == "system"
        assert "Resumo da conversa anterior" in messages[0]["content"]
        assert "Natal" in messages[-2]["content"]
        assert len(messages) == 5  # system + 2 pairs (4 messages)

    def test_load_memory_variables_no_summary_when_empty(self):
        mem = SimpleWindowMemory(k=2)
        mem.save_context({"input": "Oi"}, {"output": "Olá!"})
        result = mem.load_memory_variables({})
        messages = result["chat_history"]

        assert messages[0]["role"] == "user"
        assert all(m["role"] != "system" for m in messages)
