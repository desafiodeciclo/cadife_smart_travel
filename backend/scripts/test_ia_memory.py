import asyncio
import os
import sys
import uuid

# Add the parent directory to sys.path so we can import app modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

from app.services import ai_service
from app.core.config import get_settings

async def test_memory_context():
    settings = get_settings()
    phone = f"test_{uuid.uuid4().hex[:8]}"
    print(f"Testing AI Context Memory for phone: {phone}")
    
    print("\n--- Message 1 ---")
    msg1 = "Olá, meu nome é João Carlos."
    print(f"User: {msg1}")
    try:
        # Mocking retrieval to avoid RAG dependency during pure memory test
        original_retrieve = ai_service._retrieve_context
        ai_service._retrieve_context = lambda q, b=None: ""
        
        reply1 = await ai_service.process_message(phone, msg1)
        print(f"AI: {reply1}")
        
        print("\n--- Message 2 ---")
        msg2 = "Qual é o meu nome?"
        print(f"User: {msg2}")
        reply2 = await ai_service.process_message(phone, msg2)
        print(f"AI: {reply2}")
        
        if "João" in reply2 or "João Carlos" in reply2:
            print("\n✅ Context validation PASSED. The AI remembered the user's name.")
        else:
            print("\n❌ Context validation FAILED. The AI did not remember the user's name.")
            
        # Clean up Redis memory
        memory = ai_service.get_memory(phone)
        memory.clear()
        print("\nMemory cleared.")
        
    except Exception as e:
        print(f"\n❌ ERROR during test: {e}")
    finally:
        # Restore original function
        ai_service._retrieve_context = original_retrieve

if __name__ == "__main__":
    asyncio.run(test_memory_context())
