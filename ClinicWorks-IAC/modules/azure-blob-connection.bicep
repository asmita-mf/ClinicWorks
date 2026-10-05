@description('Name of the Azure Blob API connection')
param connectionName string

@description('Azure region')
param location string

resource azureBlobConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  kind: 'V1'

  properties: {
    displayName: connectionName

    api: {
      id: subscriptionResourceId(
        'Microsoft.Web/locations/managedApis',
        location,
        'azureblob'
      )
    }

    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {}
    }
  }
}

output connectionId string = azureBlobConnection.id

output connectionName string = azureBlobConnection.name
