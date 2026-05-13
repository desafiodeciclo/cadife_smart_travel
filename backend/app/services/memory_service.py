
from typing import Any
from langchain.memory import ConversationBufferWindowMemory

class SimpleWindowMemory(ConversationBufferWindowMemory):
    """
    A simple wrapper around ConversationBufferWindowMemory 
    to maintain compatibility with the existing ai_service.
    """
    def __init__(self, k: int = 5, memory_key: str = "chat_history", return_messages: bool = True, **kwargs: Any):
        super().__init__(k=k, memory_key=memory_key, return_messages=return_messages, **kwargs)
