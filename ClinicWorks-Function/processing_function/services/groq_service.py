import json
import os

from groq import Groq

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv(
    "GROQ_MODEL",
    "openai/gpt-oss-120b",
)

if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY is not set")

client = Groq(api_key=GROQ_API_KEY)


def extract_clinical_measurements(extracted_text: str) -> dict:

    prompt = f"""
You are a clinical document extraction assistant.

Analyze the clinical document text and extract information
needed to identify Blood Pressure and HbA1c measurements.

Return ONLY valid JSON with exactly this structure:

{{
    "patient_age": null,
    "blood_pressure": [],
    "hba1c": []
}}

Rules:

1. PATIENT AGE
- Extract the patient's age if explicitly available.
- Do not calculate or infer age.
- If unavailable, return null.

2. BLOOD PRESSURE
- Extract every Blood Pressure measurement explicitly present.
- Each measurement must contain:
  - value
  - date
  - context

Example:
{{
    "value": "120/80 mmHg",
    "date": "2026-09-20",
    "context": "current"
}}

- "date" should be null if no date is associated with the measurement.
- "context" should describe the context when explicitly stated.
- Possible contexts include:
  current, historical, previous, past, target, goal, reference, unknown
- Do not invent dates or context.
- A valid Blood Pressure must contain both systolic and diastolic values.

3. HbA1c
- Extract every HbA1c measurement explicitly present.
- Each measurement must contain:
  - value
  - date
  - context

Example:
{{
    "value": 6.2,
    "date": "2026-09-20",
    "context": "current"
}}

- Return the numeric HbA1c value without the % symbol.
- "date" should be null if no date is associated with the measurement.
- "context" should describe the context when explicitly stated.
- Possible contexts include:
  current, historical, previous, past, target, goal, reference, unknown
- Do not invent dates or context.

4. IMPORTANT
- Extract information only when explicitly present in the document.
- Do not infer or invent values.
- Ignore normal/reference ranges unless they are actual patient measurements.
- Ignore target or goal values as patient measurements.
- Ignore historical examples unless they are explicitly patient measurements.
- Do not classify HbA1c.
- Do not apply business rules.
- Do not select the final measurement.
- Return all explicitly identified candidates so that Python can apply the business rules.

Return JSON only.
Do not use markdown code fences.

Clinical document text:
{extracted_text}
"""

    response = client.chat.completions.create(
        model=GROQ_MODEL,
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
        temperature=0,
    )

    result = response.choices[0].message.content

    if not result:
        raise ValueError("Groq returned an empty response")

    try:
        return json.loads(result)
    except json.JSONDecodeError as exc:
        raise ValueError(
            f"Groq returned invalid JSON: {result}"
        ) from exc