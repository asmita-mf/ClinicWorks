from fastapi import FastAPI
from app.routes.document_route import router as document_router

from app.db.database import engine
from app.models.document_model import Base

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

Base.metadata.create_all(bind=engine)

app.include_router(document_router)
