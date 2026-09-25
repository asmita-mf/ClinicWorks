from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

import requests

from app.db.database import get_db
from app.models.document_model import ProcessedDocument
from app.services.storage_service import upload_file
from app.core.config import LOGIC_APP_URL

router = APIRouter(
    prefix="/documents",
    tags=["Documents"],
)

@router.get("/processed")
def get_processed_documents(
    db: Session = Depends(get_db),
):
    documents = (
        db.query(ProcessedDocument)
        .order_by(ProcessedDocument.created_at.desc())
        .all()
    )

    return {
        "documents": [
            {
                "id": document.id,
                "filename": document.filename,
                "blob_url": document.blob_url,
                "extracted_text": document.extracted_text,
                "document_type": document.document_type,
                "blood_pressure": document.blood_pressure,
                "hba1c": document.hba1c,
                "measure_date": document.measure_date,
                "confidence_score": document.confidence_score,
                "status": document.status,
                "created_at": document.created_at,            
            }
            for document in documents
        ]
    }

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    file_data = await file.read()

    blob_url = upload_file(
        file.filename,
        file_data,
    )

    
    # 2. Trigger Logic App
    payload = {
        "blob_name": file.filename
    }

    try:
        response = requests.post(
            LOGIC_APP_URL,
            json=payload,
            timeout=30,
        )

        response.raise_for_status()

    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to trigger Logic App: {str(exc)}"
        )

    # 3. Return immediately
    return {
        "message": "File uploaded and processing triggered successfully",
        "filename": file.filename,
        "blob_url": blob_url,
        "status": "processing",
        "logic_app_status": response.status_code,
    }