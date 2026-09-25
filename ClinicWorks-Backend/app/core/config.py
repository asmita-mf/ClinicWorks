import os

from dotenv import load_dotenv

load_dotenv()

AZURE_STORAGE_ACCOUNT_NAME = os.getenv(
    "AZURE_STORAGE_ACCOUNT_NAME"
)

AZURE_STORAGE_CONTAINER_NAME = os.getenv(
    "AZURE_STORAGE_CONTAINER_NAME"
)

if not AZURE_STORAGE_ACCOUNT_NAME:
    raise ValueError("AZURE_STORAGE_ACCOUNT_NAME is not set")

if not AZURE_STORAGE_CONTAINER_NAME:
    raise ValueError("AZURE_STORAGE_CONTAINER_NAME is not set")

DATABASE_URL = os.getenv("DATABASE_URL")    

LOGIC_APP_URL = os.getenv("LOGIC_APP_URL")