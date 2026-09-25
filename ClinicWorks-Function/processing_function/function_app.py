import azure.functions as func

app = func.FunctionApp(
    http_auth_level=func.AuthLevel.FUNCTION
)

@app.route(
    route="process-document",
    methods=["POST"],
)
def process_document(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        "Function discovery test successful",
        status_code=200
    )