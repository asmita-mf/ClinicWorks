extension graphV1

// ==================================================
// Parameters
// ==================================================

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


// ==================================================
// Common Tags
// ==================================================

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
}


// ==================================================
// Resource Names
// ==================================================

// Storage Account
// Storage account names must be lowercase and contain
// only letters and numbers.
var storageAccountName = 'st${projectName}${environment}${regionCode}${instance}'

// Storage Container
var containerName = 'cr-${projectName}-data-${environment}'

// App Services
var backendAppServiceName = 'app-${projectName}-api-${environment}-${regionCode}-${instance}'

var frontendAppServiceName = 'app-${projectName}-ui-${environment}-${regionCode}-${instance}'

// App Service Plan
var appServicePlanName = 'asp-${projectName}-${environment}-${regionCode}-${instance}'

// Function App
var functionAppName = 'fn-${projectName}-processing-${environment}-${regionCode}-${instance}'

var functionAppServicePlanName = '${appServicePlanName}-function'

// Key Vault
var keyVaultName = 'kv-${projectName}-${environment}-${instance}'

// Application Insights
var appInsightsName = 'appi-${projectName}-${environment}-${regionCode}-${instance}'

// PostgreSQL
var postgresServerName = 'pg-${projectName}-${environment}-${regionCode}-${instance}'

// Document Intelligence
var documentIntelligenceName = 'di-${projectName}-${environment}-${regionCode}-${instance}'

// Logic App
var logicAppName = 'logic-${projectName}-processing-${environment}-${regionCode}-${instance}'

// Virtual Network
var vnetName = 'vnet-${projectName}-${environment}-${regionCode}-${instance}'

// PostgreSQL Private DNS Zone
var postgresPrivateDnsZoneName = 'privatelink.postgres.database.azure.com'

// Managed Identity
var logicAppIdentityName = 'id-${projectName}-logic-${environment}-${regionCode}-${instance}'

// Function API / Microsoft Graph application
var functionApiUniqueName = '${projectName}-${environment}-${regionCode}-${instance}-function-api'

var functionApiDisplayName = '${projectName} Function API (${environment})'

var functionApiIdentifierUri = 'https://${functionAppName}.azurewebsites.net'

// Log Analytics
var logAnalyticsWorkspaceName = 'log-${projectName}-${environment}-${regionCode}-${instance}'


// ==================================================
// Storage
// ==================================================

module storage './modules/storage.bicep' = {
  name: 'storageDeployment'

  params: {
    storageAccountName: storageAccountName
    containerName: containerName
    location: location
    tags: commonTags
  }
}


// ==================================================
// Network
// ==================================================

module network './modules/network.bicep' = {
  name: 'networkDeployment'

  params: {
    vnetName: vnetName
    location: location
    tags: commonTags
  }
}


// ==================================================
// PostgreSQL Private DNS
// ==================================================

module postgresPrivateDns './modules/private-dns.bicep' = {
  name: 'postgresPrivateDnsDeployment'

  params: {
    zoneName: postgresPrivateDnsZoneName
    tags: commonTags
    vnetResourceId: network.outputs.vnetId
  }
}


// ==================================================
// Managed Identity - Logic App
// ==================================================

module logicAppIdentity './modules/managed-identity.bicep' = {
  name: 'logicAppIdentityDeployment'

  params: {
    identityName: logicAppIdentityName
    location: location
    tags: commonTags
  }
}


// ==================================================
// Monitoring
// ==================================================

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


// ==================================================
// App Service
// ==================================================

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


// ==================================================
// Function API
// ==================================================

module functionApi './modules/function-api.bicep' = {
  name: 'functionApiDeployment'

  params: {
    appUniqueName: functionApiUniqueName
    appDisplayName: functionApiDisplayName
    identifierUri: functionApiIdentifierUri
  }
}


// ==================================================
// Function App
// ==================================================

module function './modules/function.bicep' = {
  name: 'functionDeployment'

  params: {
    functionAppName: functionAppName
    appServicePlanName: functionAppServicePlanName
    location: location
    tags: commonTags

    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString

    integrationSubnetResourceId: network.outputs.functionSubnetId

    functionApiClientId: functionApi.outputs.clientId

    functionApiIdentifierUri: functionApiIdentifierUri

    logicAppPrincipalId: logicAppIdentity.outputs.principalId
  }
}


// ==================================================
// Key Vault
// ==================================================

module keyvault './modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'

  params: {
    keyVaultName: keyVaultName
    location: location
    tags: commonTags
  }
}


// ==================================================
// RBAC - Function → Storage
// ==================================================

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    storageAccountName,
    functionAppName,
    'Storage Blob Data Contributor'
  )

  scope: storageAccountResource

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )

    principalId: function.outputs.functionPrincipalId

    principalType: 'ServicePrincipal'
  }
}


// ==================================================
// RBAC - Function → Key Vault
// ==================================================
resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    keyVaultName,
    functionAppName,
    'Key Vault Secrets User'
  )

  scope: keyVaultResource

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )

    principalId: function.outputs.functionPrincipalId

    principalType: 'ServicePrincipal'
  }
}


// ==================================================
// PostgreSQL
// ==================================================

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


// ==================================================
// Document Intelligence
// ==================================================

module documentIntelligence './modules/document-intelligence.bicep' = {
  name: 'documentIntelligenceDeployment'

  params: {
    resourceName: documentIntelligenceName
    location: location
    tags: commonTags
  }
}


// ==================================================
// Logic App
// ==================================================

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


// ==================================================
// Outputs
// ==================================================

output storageAccountName string = storage.outputs.storageAccountName

output containerName string = storage.outputs.containerName

output storageAccountId string = storage.outputs.storageAccountId


// --------------------------------------------------
// App Services
// --------------------------------------------------

output backendAppServiceName string = appservice.outputs.backendAppServiceName

output frontendAppServiceName string = appservice.outputs.frontendAppServiceName

output appServicePlanName string = appservice.outputs.appServicePlanName


// --------------------------------------------------
// Function
// --------------------------------------------------

output functionAppName string = function.outputs.functionAppName

output functionApiClientId string = functionApi.outputs.clientId


// --------------------------------------------------
// Key Vault
// --------------------------------------------------

output keyVaultName string = keyvault.outputs.keyVaultName

output keyVaultId string = keyvault.outputs.keyVaultId


// --------------------------------------------------
// Monitoring
// --------------------------------------------------

output appInsightsName string = monitoring.outputs.appInsightsName


// --------------------------------------------------
// PostgreSQL
// --------------------------------------------------

output postgresServerName string = postgres.outputs.postgresServerName

output postgresServerId string = postgres.outputs.postgresServerId


// --------------------------------------------------
// Document Intelligence
// --------------------------------------------------

output documentIntelligenceName string = documentIntelligence.outputs.documentIntelligenceName

output documentIntelligenceId string = documentIntelligence.outputs.documentIntelligenceId

output documentIntelligenceEndpoint string = documentIntelligence.outputs.documentIntelligenceEndpoint


// --------------------------------------------------
// Logic App
// --------------------------------------------------

output logicAppName string = logicApp.outputs.logicAppName

output logicAppId string = logicApp.outputs.logicAppId


// --------------------------------------------------
// Network
// --------------------------------------------------

output vnetName string = network.outputs.vnetName

output vnetId string = network.outputs.vnetId
