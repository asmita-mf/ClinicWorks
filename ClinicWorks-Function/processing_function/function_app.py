import azure.functions as func

from services.blob_service import download_file, get_blob_url
from services.document_intelligence import analyze_document
# from services.groq_service import extract_clinical_measurements
# from services.database_service import save_processed_document
# from services.business_rules import (
#     select_blood_pressure,
#     select_hba1c,
#     get_measure_date,
#     calculate_confidence_score,
# )


app = func.FunctionApp(
    http_auth_level=func.AuthLevel.FUNCTION
)

@app.route(
    route="process-document",
    methods=["POST"],
)
def process_document(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        "Function discovery test successful analyze_document is required",
        status_code=200
    )