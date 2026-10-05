extension graphV1

// ==================================================
// PARAMETERS
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
// COMMON TAGS
// ==================================================

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
}


// ==================================================
// RESOURCE NAMES
// ==================================================

var storageAccountName = 'st${projectName}${environment}${regionCode}${instance}'

var containerName = 'cr-${projectName}-data-${environment}'

var backendAppServiceName = 'app-${projectName}-api-${environment}-${regionCode}-${instance}'

var frontendAppServiceName = 'app-${projectName}-ui-${environment}-${regionCode}-${instance}'

var appServicePlanName = 'asp-${projectName}-${environment}-${regionCode}-${instance}'

var functionAppName = 'fn-${projectName}-processing-${environment}-${regionCode}-${instance}'

var functionAppServicePlanName = '${appServicePlanName}-function'

var keyVaultName = 'kv-${projectName}-${environment}-${instance}'

var appInsightsName = 'appi-${projectName}-${environment}-${regionCode}-${instance}'

var postgresServerName = 'pg-${projectName}-${environment}-${regionCode}-${instance}'

var documentIntelligenceName = 'di-${projectName}-${environment}-${regionCode}-${instance}'

var logicAppName = 'logic-${projectName}-processing-${environment}-${regionCode}-${instance}'

var vnetName = 'vnet-${projectName}-${environment}-${regionCode}-${instance}'

var postgresPrivateDnsZoneName = 'privatelink.postgres.database.azure.com'

var logicAppIdentityName = 'id-${projectName}-logic-${environment}-${regionCode}-${instance}'

var functionApiUniqueName = '${projectName}-${environment}-${regionCode}-${instance}-function-api'

var functionApiDisplayName = '${projectName} Function API (${environment})'

var functionApiIdentifierUri = 'https://${functionAppName}.azurewebsites.net'

var logAnalyticsWorkspaceName = 'log-${projectName}-${environment}-${regionCode}-${instance}'

// ==================================================
// STORAGE
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
// NETWORK
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
// POSTGRESQL PRIVATE DNS
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
// LOGIC APP MANAGED IDENTITY
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
// APPLICATION INSIGHTS + LOG ANALYTICS
// ==================================================

module appInsights './modules/app-insights.bicep' = {
  name: 'appInsightsDeployment'

  params: {
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
    tags: commonTags
  }
}


// ==================================================
// APP SERVICE
// ==================================================

module appservice './modules/appservice.bicep' = {
  name: 'appServiceDeployment'

  params: {
    backendAppServiceName: backendAppServiceName
    frontendAppServiceName: frontendAppServiceName
    appServicePlanName: appServicePlanName

    location: location
    tags: commonTags

    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString

    integrationSubnetResourceId: network.outputs.appSubnetId

    // REQUIRED PARAMETERS
    storageAccountName: storage.outputs.storageAccountName
    storageContainerName: storage.outputs.containerName
    keyVaultName: keyVaultName
  }
}


// ==================================================
// FUNCTION API
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
// DOCUMENT INTELLIGENCE
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
// KEY VAULT
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
// FUNCTION APP
// ==================================================

module function './modules/function.bicep' = {
  name: 'functionDeployment'

  params: {
    functionAppName: functionAppName
    appServicePlanName: functionAppServicePlanName

    location: location
    tags: commonTags

    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString

    integrationSubnetResourceId: network.outputs.functionSubnetId

    functionApiClientId: functionApi.outputs.clientId

    functionApiIdentifierUri: functionApiIdentifierUri

    logicAppPrincipalId: logicAppIdentity.outputs.principalId

    storageAccountName: storage.outputs.storageAccountName
    storageContainerName: storage.outputs.containerName

    documentIntelligenceEndpoint: documentIntelligence.outputs.documentIntelligenceEndpoint

    keyVaultName: keyVaultName
  }
}


// ==================================================
// RBAC - FUNCTION → STORAGE
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
// RBAC - FUNCTION → KEY VAULT
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
// POSTGRESQL
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
// LOGIC APP
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
// MONITORING
// ==================================================

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoringDeployment'

  params: {
    appInsightsName: appInsights.outputs.appInsightsName

    logAnalyticsWorkspaceName: appInsights.outputs.logAnalyticsWorkspaceName

    location: location

    alertEmail: 'asmita.mfs@gmail.com'

    appServiceResourceId: appservice.outputs.backendAppServiceId

    healthCheckUrl: 'https://${appservice.outputs.backendAppServiceName}.azurewebsites.net/api/health'

    availabilityFailedLocationCount: 2
  }
}


// ==================================================
// OUTPUTS
// ==================================================

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

output appInsightsName string = appInsights.outputs.appInsightsName

output postgresServerName string = postgres.outputs.postgresServerName

output postgresServerId string = postgres.outputs.postgresServerId

output documentIntelligenceName string = documentIntelligence.outputs.documentIntelligenceName

output documentIntelligenceId string = documentIntelligence.outputs.documentIntelligenceId

output documentIntelligenceEndpoint string = documentIntelligence.outputs.documentIntelligenceEndpoint

output logicAppName string = logicApp.outputs.logicAppName

output logicAppId string = logicApp.outputs.logicAppId

output vnetName string = network.outputs.vnetName

output vnetId string = network.outputs.vnetId
