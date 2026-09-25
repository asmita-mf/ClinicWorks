import requests

from app.config import FASTAPI_BASE_URL


def upload_document(file):
    return requests.post(
        f"{FASTAPI_BASE_URL}/documents/upload",
        files={
            "file": (
                file.name,
                file.getvalue(),
                file.type,
            )
        },
        timeout=60,
    )


def get_processed_documents():
    return requests.get(
        f"{FASTAPI_BASE_URL}/documents/processed",
        timeout=10,
    )


def retry_document(document_id):
    return requests.post(
        f"{FASTAPI_BASE_URL}/documents/{document_id}/retry",
        timeout=30,
    )