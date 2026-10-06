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

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2023-01-01').keys[0].value};EndpointSuffix=core.windows.net'

resource azureWebJobsStorageSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: azureWebJobsStorageSecretName

  properties: {
    value: storageConnectionString
  }
}


output keyVaultName string = keyVault.name

output keyVaultId string = keyVault.id
