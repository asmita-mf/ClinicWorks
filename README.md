# ClinicWorks – Clinical Document Processing Platform

ClinicWorks is a cloud-based clinical document processing platform that automates the extraction, processing, validation, and storage of clinical measurements such as **Blood Pressure** and **HbA1c** from uploaded medical documents.

The application uses **Azure services, FastAPI, Streamlit, Azure Functions, Logic Apps, PostgreSQL, Azure AI Document Intelligence, and Generative AI** to provide an end-to-end document processing workflow.

---

## 1. Architecture

```text
                         ┌──────────────────────┐
                         │      User / Browser   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │  Streamlit Frontend   │
                         │      UI - Azure       │
                         └──────────┬───────────┘
                                    │
                                    │ HTTP
                                    ▼
                         ┌──────────────────────┐
                         │   FastAPI Backend    │
                         │      Azure Web App    │
                         └───────┬───────┬──────┘
                                 │       │
                    Upload File  │       │ Trigger
                                 │       ▼
                                 │  ┌───────────────────┐
                                 │  │    Logic App      │
                                 │  │ HTTP Trigger      │
                                 │  └─────────┬─────────┘
                                 │            │
                                 │            ▼
                                 │  ┌───────────────────┐
                                 │  │   Azure Function  │
                                 │  │ Document Processing│
                                 │  └──────┬─────┬──────┘
                                 │         │     │
                                 │         │     │
                                 ▼         ▼     ▼
                       ┌──────────────┐  ┌──────────────┐
                       │ Azure Blob   │  │   Document   │
                       │   Storage    │  │ Intelligence │
                       └──────────────┘  └──────────────┘
                                             │
                                             ▼
                                      ┌──────────────┐
                                      │    Groq AI   │
                                      │ Extraction / │
                                      │ Classification│
                                      └──────┬───────┘
                                             │
                                             ▼
                                      ┌──────────────┐
                                      │  PostgreSQL  │
                                      │   Database   │
                                      └──────────────┘


          ┌────────────────────────────────────────────┐
          │ Azure Monitor / Application Insights       │
          │ Logs • Metrics • Alerts • Availability     │
          └────────────────────────────────────────────┘
```

---

# 2. Main Features

- Upload clinical documents through the web interface
- Store uploaded documents in Azure Blob Storage
- Trigger asynchronous document processing through Azure Logic Apps
- Process documents using Azure Functions
- Extract text using Azure AI Document Intelligence
- Identify clinical document/measure types
- Extract:
  - Blood Pressure
  - HbA1c
  - Measurement date
  - Confidence score

- Apply business rules to extracted information
- Store processed results in PostgreSQL
- Display processed documents through the frontend
- Support document retry from the UI
- Handle processing failures
- Identify documents requiring manual review
- Monitor application health and processing failures
- Configure Azure infrastructure using Bicep
- Deploy application components through Azure DevOps CI/CD

---

# 3. Repository Structure

```text
ClinicWorks/
│
├── ClinicWorks-Backend/
│   ├── app/
│   │   ├── core/
│   │   │   └── config.py
│   │   │
│   │   ├── db/
│   │   │   └── database.py
│   │   │
│   │   ├── models/
│   │   │   └── document_model.py
│   │   │
│   │   ├── routes/
│   │   │   └── document_route.py
│   │   │
│   │   ├── services/
│   │   │   └── storage_service.py
│   │   │
│   │   └── main.py
│   │
│   ├── requirements.txt
│   └── ...
│
├── ClinicWorks-Frontend/
│   ├── app.py
│   ├── requirements.txt
│   └── ...
│
├── ClinicWorks-Function/
│   ├── processing_function/
│   │   ├── function_app.py
│   │   ├── requirements.txt
│   │   ├── services/
│   │   ├── models/
│   │   └── ...
│   │
│   └── ...
│
├── infrastructure/
│   ├── main.bicep
│   ├── modules/
│   │   ├── storage.bicep
│   │   ├── keyvault.bicep
│   │   ├── postgres.bicep
│   │   ├── function.bicep
│   │   ├── appservice.bicep
│   │   ├── logicapp.bicep
│   │   ├── networking.bicep
│   │   └── monitoring.bicep
│   └── parameters/
│       └── dev.parameters.json
│
├── tests/
│   ├── ...
│
├── azure-pipelines/
│   ├── backend.yml
│   ├── frontend.yml
│   └── function.yml
│
├── .gitignore
├── README.md
└── ...
```

> Update the folder names above if your current Bicep/YAML files use a different directory structure.

---

# 4. Application Components

## 4.1 Frontend

The frontend is implemented using **Streamlit**.

Responsibilities:

- Upload clinical documents
- Display uploaded/processed documents
- Display extracted measurements
- Display processing status
- Display confidence score
- Allow users to retry failed processing

The frontend communicates with the FastAPI backend.

---

## 4.2 Backend

The backend is implemented using **FastAPI**.

Responsibilities:

- Provide REST APIs
- Handle document uploads
- Upload documents to Azure Blob Storage
- Trigger the Logic App
- Retrieve processed documents
- Initiate document retry processing
- Provide application health endpoint

### Important endpoints

#### Health

```http
GET /health
```

Example response:

```json
{
  "status": "healthy"
}
```

#### Upload document

```http
POST /documents/upload
```

#### Get processed documents

```http
GET /documents/processed
```

#### Retry document

```http
POST /documents/{document_id}/retry
```

---

# 5. Document Processing Flow

The complete document processing flow is:

```text
1. User uploads document
          │
          ▼
2. Streamlit Frontend
          │
          ▼
3. FastAPI Backend
          │
          ├──────────────► Azure Blob Storage
          │
          ▼
4. Logic App
          │
          ▼
5. Azure Function
          │
          ▼
6. Download document from Blob Storage
          │
          ▼
7. Azure AI Document Intelligence
          │
          ▼
8. Extract document text
          │
          ▼
9. Identify measure/document type
          │
          ▼
10. Extract clinical values
          │
          ├── Blood Pressure
          ├── HbA1c
          ├── Measurement Date
          └── Confidence Score
          │
          ▼
11. Apply business rules
          │
          ▼
12. Save result to PostgreSQL
          │
          ▼
13. Frontend displays processed result
```

---

# 6. Azure Services

ClinicWorks uses the following Azure services.

| Service                        | Purpose                           |
| ------------------------------ | --------------------------------- |
| Azure App Service              | Hosts FastAPI backend             |
| Azure App Service              | Hosts Streamlit frontend          |
| Azure Functions                | Document processing               |
| Azure Logic Apps               | Processing orchestration          |
| Azure Blob Storage             | Clinical document storage         |
| Azure AI Document Intelligence | OCR/text extraction               |
| Azure Database for PostgreSQL  | Stores processing results         |
| Azure Key Vault                | Stores secrets/configuration      |
| Azure Virtual Network          | Private networking                |
| Private DNS Zone               | PostgreSQL private DNS resolution |
| Application Insights           | Application monitoring            |
| Log Analytics                  | Centralized logs                  |
| Azure Monitor                  | Metrics and alerts                |
| Azure DevOps                   | CI/CD                             |
| Bicep                          | Infrastructure as Code            |

---

# 7. Azure Resource Naming

The current development environment follows the `003` naming convention.

Examples:

```text
Resource Group
rg-clinicworks-dev-ci

Virtual Network
vnet-clinicworks-dev-ci-003

Storage Account
stclinicworksdevci003

Key Vault
kv-clinicworks-dev-003

Document Intelligence
di-clinicworks-dev-ci-003

Backend
app-clinicworks-api-dev-ci-003

Frontend
app-clinicworks-ui-dev-ci-003

Function
fn-clinicworks-processing-dev-ci-003

PostgreSQL
pg-clinicworks-dev-ci-003

Logic App
logic-clinicworks-processing-dev-ci-003

Application Insights
appi-clinicworks-dev-ci-003
```

---

# 8. Infrastructure as Code

Azure infrastructure is deployed using **Bicep**.

Bicep provides a declarative way to define and deploy Azure resources.

The infrastructure includes:

- Networking
- App Services
- Function App
- Storage
- Key Vault
- PostgreSQL
- Logic App
- Managed Identities
- Application Insights
- Log Analytics
- Monitoring alerts
- Private networking

## Deploy Bicep

Login to Azure:

```bash
az login
```

Set the subscription:

```bash
az account set \
  --subscription "73bb6a1a-1d5c-46bc-9ceb-9abe5245d7e5"
```

Create the resource group if required:

```bash
az group create \
  --name rg-clinicworks-dev-ci \
  --location centralindia
```

Validate the Bicep deployment:

```bash
az deployment group validate \
  --resource-group rg-clinicworks-dev-ci \
  --template-file infrastructure/main.bicep
```

Preview the deployment:

```bash
az deployment group what-if \
  --resource-group rg-clinicworks-dev-ci \
  --template-file infrastructure/main.bicep
```

Deploy:

```bash
az deployment group create \
  --resource-group rg-clinicworks-dev-ci \
  --template-file infrastructure/main.bicep
```

---

# 9. Security

ClinicWorks avoids storing secrets directly in source code.

Sensitive values are stored in **Azure Key Vault**.

Examples include:

- Database connection string
- Logic App URL
- Azure WebJobs Storage connection
- Other application secrets

Applications access secrets using Key Vault references and managed identities where applicable.

### Important

Never commit:

```text
local.settings.json
.env
database passwords
API keys
storage connection strings
Logic App SAS URLs
private keys
```

to Git.

---

# 10. Managed Identity

Managed identities are used to reduce the need for storing Azure credentials.

The architecture uses managed identity for services such as:

```text
Logic App
    │
    │ Managed Identity
    ▼
Azure Function
```

Key Vault access is also configured using Azure identity/RBAC.

---

# 11. Private Networking

PostgreSQL is configured with private networking.

The architecture includes:

```text
Azure VNet
│
├── Application Subnet
│   └── Backend
│
├── Function Subnet
│   └── Function App
│
└── PostgreSQL Subnet
    └── PostgreSQL Flexible Server
```

A private DNS zone is used for PostgreSQL name resolution.

The PostgreSQL server does not need to be publicly accessible.

---

# 12. Database

The application uses **PostgreSQL Flexible Server**.

Database:

```text
clinicworks
```

Main table:

```text
processed_documents
```

### Document schema

| Column           | Type     | Description                 |
| ---------------- | -------- | --------------------------- |
| id               | Integer  | Primary key                 |
| filename         | String   | Uploaded filename           |
| blob_url         | Text     | Blob Storage location       |
| extracted_text   | Text     | OCR/extracted document text |
| document_type    | String   | Identified document type    |
| blood_pressure   | String   | Blood pressure value        |
| hba1c            | String   | HbA1c value                 |
| measure_date     | DateTime | Measurement date            |
| confidence_score | Float    | Extraction confidence       |
| status           | String   | Processing status           |
| created_at       | DateTime | Record creation time        |

---

# 13. Processing Status

Documents can have statuses such as:

```text
Processing
Processed
Needs Review
Failed
```

Documents with low confidence or incomplete information can be marked:

```text
Needs Review
```

This allows users to manually review uncertain extraction results.

---

# 14. Retry Processing

Users can retry document processing from the frontend.

Flow:

```text
User clicks Retry
       │
       ▼
Frontend
       │
       ▼
POST /documents/{document_id}/retry
       │
       ▼
FastAPI Backend
       │
       ▼
Logic App
       │
       ▼
Azure Function
       │
       ▼
Document Processing
       │
       ▼
PostgreSQL
```

The retry operation reuses the original document stored in Blob Storage.

---

# 15. Monitoring

ClinicWorks uses **Azure Monitor and Application Insights** for monitoring.

Monitoring covers:

- Application availability
- HTTP 5xx errors
- Unhandled exceptions
- CPU usage
- Memory usage
- Function processing failures
- Blob Storage failures
- PostgreSQL connection failures
- Document Intelligence failures
- Logic App failures
- AI processing failures
- Low-confidence documents
- Documents requiring review

---

# 16. Health Monitoring

Backend health endpoint:

```http
GET /health
```

Expected:

```json
{
  "status": "healthy"
}
```

The availability test monitors this endpoint.

---

# 17. Logging

Application logs can be viewed through Azure Application Insights and Log Analytics.

Useful information includes:

```text
Document upload
Document processing
OCR extraction
AI extraction
Database connection
Database commit
Processing failures
Dependency failures
Retry operations
```

---

# 18. CI/CD

Azure DevOps is used for automated deployment.

The repository contains separate pipelines for:

```text
Backend
Frontend
Function
```

The pipelines use path-based triggers.

Example:

```yaml
trigger:
  branches:
    include:
      - main

  paths:
    include:
      - ClinicWorks-Backend/**
```

This means changes to the backend trigger the backend pipeline without unnecessarily deploying the other components.

---

# 19. Backend Deployment

The backend pipeline:

```text
Git Push
   │
   ▼
Azure DevOps
   │
   ▼
Install Python dependencies
   │
   ▼
Package Backend
   │
   ▼
Deploy to Azure App Service
   │
   ▼
app-clinicworks-api-dev-ci-003
```

The backend runs using Gunicorn with Uvicorn workers:

```bash
gunicorn -k uvicorn.workers.UvicornWorker app.main:app
```

---

# 20. Function Deployment

The Function pipeline:

```text
Git Push
   │
   ▼
Azure DevOps
   │
   ▼
Install Function dependencies
   │
   ▼
Package Function
   │
   ▼
Deploy Function
   │
   ▼
fn-clinicworks-processing-dev-ci-003
```

---

# 21. Frontend Deployment

The Streamlit frontend is deployed to:

```text
app-clinicworks-ui-dev-ci-003
```

The frontend communicates with the backend through the configured backend URL.

---

# 22. Environment Configuration

Application configuration should be provided through Azure App Service / Function App configuration and Key Vault.

Typical backend configuration:

```text
DATABASE_URL
LOGIC_APP_URL
```

Typical Function configuration:

```text
DATABASE_URL
AzureWebJobsStorage
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT
AZURE_DOCUMENT_INTELLIGENCE_KEY
```

Secrets should not be hardcoded.

---

# 23. Local Development

## Clone repository

```bash
git clone <repository-url>
cd ClinicWorks
```

## Backend

```bash
cd ClinicWorks-Backend
```

Create virtual environment:

```bash
python3 -m venv .venv
```

Activate:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run FastAPI:

```bash
uvicorn app.main:app --reload
```

The backend will normally be available at:

```text
http://localhost:8000
```

Swagger documentation:

```text
http://localhost:8000/docs
```

---

# 24. Frontend Local Development

```bash
cd ClinicWorks-Frontend
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run Streamlit:

```bash
streamlit run app.py
```

---

# 25. Function Local Development

Navigate to the Function directory:

```bash
cd ClinicWorks-Function/processing_function
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Start Azure Functions Core Tools:

```bash
func start
```

The local Function configuration should be stored in:

```text
local.settings.json
```

Do not commit this file.

---

# 26. Testing

API health:

```bash
curl -i https://app-clinicworks-api-dev-ci-003.azurewebsites.net/health
```

Get processed documents:

```bash
curl -i \
  https://app-clinicworks-api-dev-ci-003.azurewebsites.net/documents/processed
```

Logic App processing can be tested by sending a JSON payload containing the Blob filename:

```json
{
  "blob_name": "sample-document.pdf"
}
```

---

# 27. End-to-End Test

A complete test should verify:

### Step 1

Upload a clinical document through the UI.

### Step 2

Verify the file appears in Blob Storage.

### Step 3

Verify the Logic App is triggered.

### Step 4

Verify the Function starts processing.

### Step 5

Verify Document Intelligence extracts the document text.

### Step 6

Verify clinical values are extracted.

Example:

```text
Blood Pressure: 120/80
HbA1c: 6.2
```

### Step 7

Verify the result is saved to PostgreSQL.

### Step 8

Verify the frontend displays the processed document.

### Step 9

Test a failed document.

### Step 10

Click Retry and verify:

```text
Frontend
 → Backend
 → Logic App
 → Function
 → PostgreSQL
```

---

# 28. Error Handling

The application handles failures at multiple stages.

Examples:

```text
Blob Storage unavailable
        ↓
Processing failure

Document Intelligence unavailable
        ↓
Processing failure

PostgreSQL unavailable
        ↓
Database dependency failure

Function unavailable
        ↓
Logic App failure

Low AI confidence
        ↓
Needs Review
```

Monitoring alerts are configured for important failures.

---

# 29. Deployment Workflow

The recommended deployment process is:

```text
Developer
    │
    ▼
Git Commit
    │
    ▼
Git Push
    │
    ▼
Azure DevOps
    │
    ├──────────────► Backend Pipeline
    │
    ├──────────────► Frontend Pipeline
    │
    └──────────────► Function Pipeline
                       │
                       ▼
                  Azure Services
                       │
                       ▼
                 End-to-End Test
                       │
                       ▼
                  Monitoring
```

Infrastructure changes follow:

```text
Bicep
  │
  ▼
Validate
  │
  ▼
What-If
  │
  ▼
Deploy
  │
  ▼
Validate Azure Resources
```

---

# 30. Troubleshooting

## Backend does not start

Check App Service logs:

```bash
az webapp log tail \
  --resource-group rg-clinicworks-dev-ci \
  --name app-clinicworks-api-dev-ci-003
```

Verify dependencies:

```bash
pip install -r ClinicWorks-Backend/requirements.txt
```

Ensure the application contains:

```text
fastapi
uvicorn
gunicorn
```

---

## PostgreSQL table does not exist

Check the database and application startup.

The backend creates the SQLAlchemy tables during startup in the development setup.

The expected table is:

```text
processed_documents
```

---

## Function fails

Check Function logs:

```bash
az functionapp log tail \
  --resource-group rg-clinicworks-dev-ci \
  --name fn-clinicworks-processing-dev-ci-003
```

Check Function App settings:

```bash
az functionapp config appsettings list \
  --resource-group rg-clinicworks-dev-ci \
  --name fn-clinicworks-processing-dev-ci-003
```

Do not expose secret values when sharing output.

---

## Logic App fails

Check:

- Trigger history
- Function HTTP response
- Function availability
- Managed identity permissions
- Function App URL
- Payload format

Expected payload:

```json
{
  "blob_name": "document.pdf"
}
```

---

# 31. Security Best Practices

- Use Azure Key Vault for secrets.
- Use managed identities wherever possible.
- Do not commit `.env` files.
- Do not commit `local.settings.json`.
- Do not commit database passwords.
- Do not commit API keys.
- Do not commit Storage connection strings.
- Do not expose Logic App SAS URLs.
- Use private networking for PostgreSQL.
- Use RBAC instead of access keys where supported.
- Rotate credentials if accidentally exposed.
- Use HTTPS for application communication.

---

# 32. Technologies Used

### Backend

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL
- Requests

### Frontend

- Python
- Streamlit

### AI / Document Processing

- Azure AI Document Intelligence
- Groq
- Large Language Models
- Prompt-based extraction

### Azure

- Azure App Service
- Azure Functions
- Azure Logic Apps
- Azure Blob Storage
- Azure Database for PostgreSQL
- Azure Key Vault
- Azure Virtual Network
- Private DNS
- Application Insights
- Azure Monitor
- Log Analytics
- Managed Identity

### DevOps

- Git
- GitHub
- Azure DevOps
- Azure Pipelines
- Bicep
- Azure CLI

---

# 33. Current Environment

```text
Environment: Development
Azure Region: Central India
Infrastructure: Bicep
CI/CD: Azure DevOps
Database: PostgreSQL Flexible Server
Networking: Private
Monitoring: Application Insights + Azure Monitor
```

---

# 34. Project Goal

The goal of ClinicWorks is to provide a reliable and scalable clinical document processing workflow that can:

1. Accept clinical documents.
2. Store documents securely.
3. Extract information automatically.
4. Apply AI-assisted processing.
5. Validate extracted measurements.
6. Store structured results.
7. Allow manual review when confidence is low.
8. Support retry processing.
9. Provide monitoring and alerting.
10. Deploy infrastructure and application components consistently using Infrastructure as Code and CI/CD.

---

# 35. Future Improvements

Potential future improvements include:

- Asynchronous document processing using queues
- Azure Service Bus integration
- Improved AI extraction validation
- Automated database migrations
- Automated integration testing
- Blue/green or slot-based deployments
- Enhanced role-based access control
- Centralized dashboarding
- Improved retry policies
- Dead-letter processing for failed documents
- Production environment with separate configuration
- Automated Bicep deployment through CI/CD
- Automated security scanning

---

## 36. Summary

ClinicWorks demonstrates an end-to-end Azure cloud architecture combining:

```text
Streamlit
    ↓
FastAPI
    ↓
Blob Storage
    ↓
Logic App
    ↓
Azure Function
    ↓
Document Intelligence
    ↓
AI Processing
    ↓
PostgreSQL
    ↓
Streamlit Dashboard
```

The infrastructure is managed using **Bicep**, application deployment is automated using **Azure DevOps**, and the platform is monitored using **Application Insights and Azure Monitor**.

This architecture provides a foundation for building a secure, maintainable, and production-oriented clinical document processing platform.
