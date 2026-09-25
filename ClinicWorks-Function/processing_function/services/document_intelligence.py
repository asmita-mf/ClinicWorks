import os

from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential


ENDPOINT = os.getenv("AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT")
KEY = os.getenv("AZURE_DOCUMENT_INTELLIGENCE_KEY")

if not ENDPOINT:
    raise ValueError(
        "AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT is not set"
    )

if not KEY:
    raise ValueError(
        "AZURE_DOCUMENT_INTELLIGENCE_KEY is not set"
    )


client = DocumentIntelligenceClient(
    endpoint=ENDPOINT,
    credential=AzureKeyCredential(KEY),
)


def analyze_document(file_data: bytes) -> str:
    poller = client.begin_analyze_document(
        "prebuilt-read",
        body=file_data,
    )

    result = poller.result()

    extracted_lines = []

    for page in result.pages:
        for line in page.lines:
            extracted_lines.append(line.content)

    return "\n".join(extracted_lines)