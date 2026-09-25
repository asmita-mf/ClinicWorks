import os

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


AZURE_STORAGE_ACCOUNT_NAME = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
AZURE_STORAGE_CONTAINER_NAME = os.getenv("AZURE_STORAGE_CONTAINER_NAME")

if not AZURE_STORAGE_ACCOUNT_NAME:
    raise ValueError("AZURE_STORAGE_ACCOUNT_NAME is not set")

if not AZURE_STORAGE_CONTAINER_NAME:
    raise ValueError("AZURE_STORAGE_CONTAINER_NAME is not set")


ACCOUNT_URL = (
    f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
)

credential = DefaultAzureCredential()

blob_service_client = BlobServiceClient(
    account_url=ACCOUNT_URL,
    credential=credential,
)

container_client = blob_service_client.get_container_client(
    AZURE_STORAGE_CONTAINER_NAME
)


def download_file(blob_name: str) -> bytes:
    blob_client = container_client.get_blob_client(blob_name)

    download_stream = blob_client.download_blob()

    return download_stream.readall()

def get_blob_url(blob_name: str) -> str:
    blob_client = container_client.get_blob_client(blob_name)
    return blob_client.url