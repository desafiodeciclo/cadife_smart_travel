"""Stub for memory_service — TODO: implement proper memory management."""

from typing import List

class SimpleWindowMemory:
    """In-memory windowed conversation memory (stub)."""

    def __init__(self, window_size: int = 10) -> None:
        self.window_size = window_size
        self.messages: List[dict] = []

    def add_message(self, role: str, content: str) -> None:
        self.messages.append({"role": role, "content": content})
        if len(self.messages) > self.window_size:
            self.messages.pop(0)

    def get_messages(self) -> List[dict]:
        return self.messages.copy()

    def clear(self) -> None:
        self.messages.clear()
