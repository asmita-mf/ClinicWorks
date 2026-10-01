import json
import logging

import azure.functions as func

from services.blob_service import download_file, get_blob_url
from services.document_intelligence import analyze_document
from services.groq_service import extract_clinical_measurements
from services.database_service import save_processed_document
from services.business_rules import (
    select_blood_pressure,
    select_hba1c,
    get_measure_date,
    calculate_confidence_score,
)

logger = logging.getLogger(__name__)

# app = func.FunctionApp(
#     http_auth_level=func.AuthLevel.FUNCTION
# )
app = func.FunctionApp(
    http_auth_level=func.AuthLevel.ANONYMOUS
)


@app.route(
    route="process-document",
    methods=["POST"],
)
def process_document(req: func.HttpRequest) -> func.HttpResponse:

    blob_name = req.params.get("blob_name")

    if not blob_name:
        try:
            body = req.get_json()
            blob_name = body.get("blob_name")
        except ValueError:
            pass

    if not blob_name:
        return func.HttpResponse(
            "blob_name is required",
            status_code=400,
        )

    try:
        # 1. Download document from Blob Storage
        try:
            file_data = download_file(blob_name)
        except Exception:
            logger.exception(
                "DEPENDENCY_FAILURE | dependency=BlobStorage | blob=%s",
                blob_name,
            )
            raise

        # 2. Extract text using Azure Document Intelligence
        try:
            extracted_text = analyze_document(file_data)
        except Exception:
            logger.exception(
                "DEPENDENCY_FAILURE | dependency=DocumentIntelligence | blob=%s",
                blob_name,
            )
            raise

        # 3. Extract measurement candidates using Groq
        try:
            measurements = extract_clinical_measurements(
                extracted_text
            )
        except Exception:
            logger.exception(
                "DEPENDENCY_FAILURE | dependency=Groq | blob=%s",
                blob_name,
            )
            raise

        patient_age = measurements.get("patient_age")

        blood_pressure_candidates = measurements.get(
            "blood_pressure",
            [],
        )

        hba1c_candidates = measurements.get(
            "hba1c",
            [],
        )

        # 4. Apply Blood Pressure business rules
        blood_pressure = select_blood_pressure(
            blood_pressure_candidates,
            patient_age,
        )

        # 5. Apply HbA1c business rules
        hba1c = select_hba1c(
            hba1c_candidates,
        )

        print("Selected Blood Pressure:", blood_pressure)
        print("Selected HbA1c:", hba1c)

        measure_date = get_measure_date(
            blood_pressure_candidates,
            hba1c_candidates,
            blood_pressure,
            hba1c,
        )

        confidence_score = calculate_confidence_score(
            measurements,
            blood_pressure,
            hba1c,
            measure_date,
        )

        # 6. Determine document type
        if blood_pressure and hba1c:
            document_type = "BP+A1C"
        elif blood_pressure:
            document_type = "BP"
        elif hba1c:
            document_type = "A1C"
        else:
            document_type = None

        # 7. Determine processing status
        if document_type and confidence_score >= 60:
            status = "Success"
        elif document_type:
            status = "Needs Review"
        else:
            status = "Needs Review"

        # 8. Save result to PostgreSQL
        try:
            document = save_processed_document(
                filename=blob_name,
                blob_url=get_blob_url(blob_name),
                extracted_text=extracted_text,
                document_type=document_type,
                blood_pressure=blood_pressure,
                hba1c=hba1c,
                measure_date=measure_date,
                confidence_score=confidence_score,
                status=status,
            )
        except Exception:
            logger.exception(
                "DEPENDENCY_FAILURE | dependency=PostgreSQL | blob=%s",
                blob_name,
            )
            raise

        # 9. Return response
        return func.HttpResponse(
            json.dumps(
                {
                    "id": document.id,
                    "filename": document.filename,
                    "document_type": document.document_type,
                    "blood_pressure": document.blood_pressure,
                    "hba1c": document.hba1c,
                    "measure_date": (
                        measure_date.isoformat()
                        if measure_date
                        else None
                    ),
                    "confidence_score": confidence_score,
                    "status": document.status,
                }
            ),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as exc:

        logger.exception(
            "Document processing failed for blob: %s",
            blob_name,
        )

        return func.HttpResponse(
            f"Document processing failed: {str(exc)}",
            status_code=500,
        )