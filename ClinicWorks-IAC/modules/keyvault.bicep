@description('Name of the Key Vault')
param keyVaultName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

@description('Name of the Storage Account used by the Function App')
param storageAccountName string

@description('Resource ID of the Storage Account')
param storageAccountId string

@description('Name of the AzureWebJobsStorage secret in Key Vault')
param azureWebJobsStorageSecretName string = 'azure-webjobs-storage'

@secure()
@description('Document Intelligence API key to store in Key Vault')
param documentIntelligenceKey string

@description('Name of the Document Intelligence API key secret in Key Vault')
param documentIntelligenceKeySecretName string = 'secret-clinicworks-document-intelligence-endpoint'


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location

  tags: tags

  properties: {
    tenantId: subscription().tenantId

    sku: {
      family: 'A'
      name: 'standard'
    }

    enableRbacAuthorization: true

    enabledForTemplateDeployment: false
  }
}


// ------------------------------------------
// AzureWebJobsStorage
//
// Store the Storage Account connection
// string securely in Key Vault.
// ------------------------------------------

var storageEndpointSuffix = environment().suffixes.storage
var storageAccountKey = listKeys(storageAccountId, '2023-05-01').keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;EndpointSuffix=${storageEndpointSuffix};AccountName=${storageAccountName};AccountKey=${storageAccountKey};BlobEndpoint=https://${storageAccountName}.blob.${storageEndpointSuffix}/;FileEndpoint=https://${storageAccountName}.file.${storageEndpointSuffix}/;QueueEndpoint=https://${storageAccountName}.queue.${storageEndpointSuffix}/;TableEndpoint=https://${storageAccountName}.table.${storageEndpointSuffix}/'

resource azureWebJobsStorageSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: azureWebJobsStorageSecretName

  properties: {
    value: storageConnectionString
  }
}

resource documentIntelligenceKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: documentIntelligenceKeySecretName

  properties: {
    value: documentIntelligenceKey
  }
}


output keyVaultName string = keyVault.name

output keyVaultId string = keyVault.id
