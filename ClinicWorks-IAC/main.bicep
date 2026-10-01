extension graphV1

@description('Name of the project')
param projectName string

@description('Deployment environment')
@allowed([
  'dev'
  'test'
  'prod'
])
@minLength(2)
@maxLength(10)
param environment string

@description('Short Azure region code')
param regionCode string

@description('Resource instance number')
param instance string

@description('Azure region')
param location string

@description('PostgreSQL administrator username')
param postgresAdminUsername string

@secure()
@description('PostgreSQL administrator password')
param postgresAdminPassword string

// --------------------------------------------------
// Common tags
// --------------------------------------------------

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
}


// --------------------------------------------------
// Resource names
// --------------------------------------------------

var storageAccountName = 'st${projectName}${environment}${regionCode}${instance}'

var containerName = 'cr-${projectName}-data-${environment}'

var backendAppServiceName = 'app-${projectName}-bicep-api-${environment}-${regionCode}-${instance}'

var frontendAppServiceName = 'app-${projectName}-bicep-ui-${environment}-${regionCode}-${instance}'

var appServicePlanName = 'asp-${projectName}-${environment}-${regionCode}-${instance}'

var functionAppName = 'fn-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var keyVaultName = 'kv-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var appInsightsName = 'appi-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var postgresServerName = 'pg-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var documentIntelligenceName = 'di-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var logicAppName = 'logic-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var vnetName = 'vnet-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var postgresPrivateDnsZoneName = 'privatelink.postgres.database.azure.com'

var logicAppIdentityName = 'id-${projectName}-bicep-${environment}-${regionCode}-${instance}'

var functionApiUniqueName = '${projectName}-${environment}-${regionCode}-${instance}-function-api'

var functionApiDisplayName = '${projectName} Function API (${environment})'

var functionApiIdentifierUri = 'https://${functionAppName}.azurewebsites.net'

var logAnalyticsWorkspaceName = 'log-${projectName}-bicep-${environment}-${regionCode}-${instance}'

// --------------------------------------------------
// Existing resource reference
// --------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// --------------------------------------------------
// Storage
// --------------------------------------------------

module storage './modules/storage.bicep' = {
  name: 'storageDeployment'

  params: {
    storageAccountName: storageAccountName
    containerName: containerName
    location: location
    tags: commonTags
  }
}


// --------------------------------------------------
// App Service
// --------------------------------------------------

module appservice './modules/appservice.bicep' = {

  name: 'appServiceDeployment'

  params: {

    backendAppServiceName: backendAppServiceName
    frontendAppServiceName: frontendAppServiceName
    appServicePlanName: appServicePlanName
    location: location
    tags: commonTags
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    integrationSubnetResourceId: network.outputs.appSubnetId

  }

}

// --------------------------------------------------
// Function
// --------------------------------------------------

module function './modules/function.bicep' = {
  name: 'functionDeployment'

  params: {
    functionAppName: functionAppName
    appServicePlanName: '${appServicePlanName}-function'
    location: location
    tags: commonTags
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    integrationSubnetResourceId: network.outputs.functionSubnetId
    functionApiClientId: functionApi.outputs.clientId
    functionApiIdentifierUri: functionApiIdentifierUri
    logicAppPrincipalId: logicAppIdentity.outputs.principalId
  }
}

// --------------------------------------------------
// KeyVault
// --------------------------------------------------

module keyvault './modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'

  params: {
    keyVaultName: keyVaultName
    location: location
    tags: commonTags
  }
}

// --------------------------------------------------
// RBAC - Function → Storage
// --------------------------------------------------

resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    storageAccountName,
    functionAppName,
    'Storage Blob Data Contributor'
  )

  scope: storageAccount

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )

    principalId: function.outputs.functionPrincipalId

    principalType: 'ServicePrincipal'
  }
}

// --------------------------------------------------
// RBAC - Function → Key Vault
// --------------------------------------------------

resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    keyVaultName,
    functionAppName,
    'Key Vault Secrets User'
  )

  scope: keyVault

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )

    principalId: function.outputs.functionPrincipalId

    principalType: 'ServicePrincipal'
  }
}

// --------------------------------------------------
// Monitoring
// --------------------------------------------------

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoringDeployment'

  params: {
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
    tags: commonTags
    alertEmail: 'asmita.mfs@gmail.com'

    appServiceResourceId: resourceId(
      'Microsoft.Web/sites',
      backendAppServiceName
    )

    healthCheckUrl: 'https://${backendAppServiceName}.azurewebsites.net/api/health'

    availabilityFailedLocationCount: 2
  }
}

// --------------------------------------------------
// Postgres
// --------------------------------------------------
module postgres './modules/postgres.bicep' = {
  name: 'postgresDeployment'
  params: {
    serverName: postgresServerName
    location: location
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    tags: commonTags
    delegatedSubnetResourceId: network.outputs.postgresSubnetId
    privateDnsZoneArmResourceId: postgresPrivateDns.outputs.privateDnsZoneId
  }
}

// --------------------------------------------------
// DocumentIntelligence
// --------------------------------------------------
module documentIntelligence './modules/document-intelligence.bicep' = {
  name: 'documentIntelligenceDeployment'
  params: {
    resourceName: documentIntelligenceName
    location: location
    tags: commonTags
  }
}

// --------------------------------------------------
// LogicApp
// --------------------------------------------------
module logicApp './modules/logic-app.bicep' = {
  name: 'logicAppDeployment'
  params: {
    logicAppName: logicAppName
    location: location
    tags: commonTags
    functionAppName: functionAppName
    logicAppIdentityId: logicAppIdentity.outputs.identityId
  }
}

// --------------------------------------------------
// Network
// --------------------------------------------------
module network './modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    vnetName: vnetName
    location: location
    tags: commonTags
  }
}

// --------------------------------------------------
// PostgresPrivateDns
// --------------------------------------------------
module postgresPrivateDns './modules/private-dns.bicep' = {
  name: 'postgresPrivateDnsDeployment'

  params: {
    zoneName: postgresPrivateDnsZoneName
    tags: commonTags
    vnetResourceId: network.outputs.vnetId
  }
}

// --------------------------------------------------
// LogicAppIdentity
// --------------------------------------------------
module logicAppIdentity './modules/managed-identity.bicep' = {
  name: 'logicAppIdentityDeployment'
  params: {
    identityName: logicAppIdentityName
    location: location
    tags: commonTags
  }
}

module functionApi './modules/function-api.bicep' = {
  name: 'functionApiDeployment'

  params: {
    appUniqueName: functionApiUniqueName
    appDisplayName: functionApiDisplayName
    identifierUri: functionApiIdentifierUri
  }
}

// --------------------------------------------------
// Outputs
// --------------------------------------------------

output storageAccountName string = storage.outputs.storageAccountName

output containerName string = storage.outputs.containerName

output storageAccountId string = storage.outputs.storageAccountId

output backendAppServiceName string = appservice.outputs.backendAppServiceName

output frontendAppServiceName string = appservice.outputs.frontendAppServiceName

output appServicePlanName string = appservice.outputs.appServicePlanName

output functionAppName string = function.outputs.functionAppName

output functionApiClientId string = functionApi.outputs.clientId

output keyVaultName string = keyvault.outputs.keyVaultName

output keyVaultId string = keyvault.outputs.keyVaultId

output appInsightsName string = monitoring.outputs.appInsightsName

output postgresServerName string = postgres.outputs.postgresServerName

output postgresServerId string = postgres.outputs.postgresServerId

output documentIntelligenceName string = documentIntelligence.outputs.documentIntelligenceName

output documentIntelligenceId string = documentIntelligence.outputs.documentIntelligenceId

output documentIntelligenceEndpoint string = documentIntelligence.outputs.documentIntelligenceEndpoint

output logicAppName string = logicApp.outputs.logicAppName

output logicAppId string = logicApp.outputs.logicAppId

output vnetName string = network.outputs.vnetName

output vnetId string = network.outputs.vnetId
