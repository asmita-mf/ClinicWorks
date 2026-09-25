from app.services.groq_service import (
    extract_clinical_measurements,
)


text = """
Patient Name: John Doe
Patient ID: CW-1001
Blood Pressure: 120/80 mmHg
HbA1c: 6.2%
Notes: Routine clinical assessment.
"""


result = extract_clinical_measurements(text)

print("\n--- OpenAI Result ---\n")
print(result)