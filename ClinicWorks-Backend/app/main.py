from fastapi import FastAPI
from app.routes.document_route import router as document_router

app = FastAPI(
    title="ClinicWorks",
    description="Clinical Document Processing Platform",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "application": "ClinicWorks",
        "status": "running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
    }


app.include_router(document_router)
