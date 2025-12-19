import redis
import os
from dotenv import load_dotenv

load_dotenv()

# Initialize Redis client
# decode_responses=True ensures that responses are returned as strings (not bytes)
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),  # Redis server host
    port=int(os.getenv("REDIS_PORT", "6379")),   # Redis server port
    decode_responses=True
)
