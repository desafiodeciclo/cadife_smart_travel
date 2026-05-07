import asyncio
import time
import os
import sys

# Add the parent directory to sys.path so we can import app modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

try:
    import redis.asyncio as redis
except ImportError:
    print("Error: redis package not installed. Run 'pip install redis'")
    sys.exit(1)

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env.staging'))

from app.core.config import get_settings

async def test_redis_connection():
    settings = get_settings()
    
    print(f"Testing Redis Connection for Environment: {settings.APP_ENV}")
    print(f"Redis URL: {settings.REDIS_URL}")
    print(f"Redis Prefix: {settings.REDIS_PREFIX}")
    
    try:
        # Initializing the client
        start_time = time.time()
        client = redis.from_url(settings.REDIS_URL, decode_responses=True)
        
        # Ping
        ping_result = await client.ping()
        ping_time = time.time() - start_time
        print(f"✅ PING successful in {ping_time:.4f}s: {ping_result}")
        
        # Test write
        test_key = f"{settings.REDIS_PREFIX}health_check_test"
        write_start = time.time()
        await client.set(test_key, "OK", ex=10) # Set key with 10s expiration
        write_time = time.time() - write_start
        print(f"✅ WRITE successful in {write_time:.4f}s")
        
        # Test read
        read_start = time.time()
        value = await client.get(test_key)
        read_time = time.time() - read_start
        print(f"✅ READ successful in {read_time:.4f}s. Value: {value}")
        
        # Clean up
        await client.delete(test_key)
        print(f"✅ CLEANUP successful")
        
        await client.aclose()
        print("\nAll health checks passed! The Redis instance is ready.")
        
    except Exception as e:
        print(f"\n❌ ERROR connecting to Redis: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # To run this script with staging settings, you should set:
    # APP_ENV=staging python scripts/test_redis_staging.py
    asyncio.run(test_redis_connection())
