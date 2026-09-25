import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from models.document_model import ProcessedDocument


def get_session():
    database_url = os.getenv("DATABASE_URL")

    if not database_url:
        raise ValueError("DATABASE_URL is not set")

    engine = create_engine(
        database_url,
        pool_pre_ping=True,
    )

    SessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )

    return SessionLocal()


def save_processed_document(
    filename: str,
    blob_url: str,
    extracted_text: str,
    document_type: str | None,
    blood_pressure: str | None,
    hba1c: str | None,
    measure_date,
    confidence_score: float | None,
    status: str,
):
    print("Connecting to PostgreSQL...")

    db = get_session()

    print("PostgreSQL session created")

    try:
        document = ProcessedDocument(
            filename=filename,
            blob_url=blob_url,
            extracted_text=extracted_text,
            document_type=document_type,
            blood_pressure=blood_pressure,
            hba1c=hba1c,
            measure_date=measure_date,
            confidence_score=confidence_score,
            status=status,
        )

        print("Document object created")

        db.add(document)

        print("Committing document to PostgreSQL...")

        db.commit()

        print("PostgreSQL commit successful")

        db.refresh(document)

        print(f"Document saved with ID: {document.id}")

        return document

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()