from app.db.database import engine
from app.models.document_model import Base


Base.metadata.create_all(bind=engine)

print("Database tables created successfully.")