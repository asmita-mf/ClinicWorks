from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

storage_account = "stclinicworksdevci"
container_name = "clinicworks-data-dev"

account_url = f"https://{storage_account}.blob.core.windows.net"

credential = DefaultAzureCredential()

client = BlobServiceClient(
    account_url=account_url,
    credential=credential,
)

container_client = client.get_container_client(container_name)

print("Connected to Azure Blob Storage!")

for blob in container_client.list_blobs():
    print(blob.name)