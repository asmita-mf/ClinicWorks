extension graphV1

@description('Unique name for the Function API application')
param appUniqueName string

@description('Display name for the Function API application')
param appDisplayName string

@description('Identifier URI for the Function API')
param identifierUri string

resource functionApiApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appUniqueName
  displayName: appDisplayName
  signInAudience: 'AzureADMyOrg'

  identifierUris: [
    identifierUri
  ]

  api: {
    requestedAccessTokenVersion: 2
  }
}

resource functionApiServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: functionApiApp.appId
}

output clientId string = functionApiApp.appId
output objectId string = functionApiApp.id
output servicePrincipalId string = functionApiServicePrincipal.id