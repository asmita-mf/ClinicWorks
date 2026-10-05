@description('Name of the Azure Blob API connection')
param connectionName string

@description('Azure region')
param location string

@description('Storage account name')
param storageAccountName string

@description('User-assigned managed identity resource ID')
param managedIdentityResourceId string

resource azureBlobConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location

  properties: {
    displayName: connectionName

    api: {
      id: subscriptionResourceId(
        'Microsoft.Web/locations/managedApis',
        location,
        'azureblob'
      )
    }

    parameterValues: {
      storageAccountEndpoint: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
      managedIdentity: managedIdentityResourceId
    }
  }
}

output connectionId string = azureBlobConnection.id

output connectionName string = azureBlobConnection.name
