from datetime import datetime

from sqlalchemy import Column, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class ProcessedDocument(Base):
    __tablename__ = "processed_documents"

    id = Column(Integer, primary_key=True, index=True)

    filename = Column(String(255), nullable=False)

    blob_url = Column(Text, nullable=False)

    extracted_text = Column(Text, nullable=True)

    document_type = Column(String(20), nullable=True)

    blood_pressure = Column(String(100), nullable=True)

    hba1c = Column(String(100), nullable=True)

    measure_date = Column(DateTime, nullable=True)

    confidence_score = Column(Float, nullable=True)

    status = Column(String(50), nullable=False)

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )