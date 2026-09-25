from pathlib import Path

from app.services.document_intelligence_service import analyze_document


file_path = Path("tests/file.pdf")

with open(file_path, "rb") as file:
    file_data = file.read()

print("File size:", len(file_data), "bytes")

result = analyze_document(file_data)

print("\n--- Extracted Text ---\n")

for page in result.pages:
    for line in page.lines:
        print(line.content)