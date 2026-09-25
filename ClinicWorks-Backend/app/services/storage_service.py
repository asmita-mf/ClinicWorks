from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

from app.core.config import (
    AZURE_STORAGE_ACCOUNT_NAME,
    AZURE_STORAGE_CONTAINER_NAME,
)


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


def upload_file(file_name: str, file_data: bytes) -> str:
    blob_client = container_client.get_blob_client(file_name)

    blob_client.upload_blob(
        file_data,
        overwrite=True,
    )

    return blob_client.url