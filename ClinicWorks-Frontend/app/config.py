import os


FASTAPI_BASE_URL = os.getenv(
    "FASTAPI_BASE_URL",
    "http://127.0.0.1:8000",
).rstrip("/")