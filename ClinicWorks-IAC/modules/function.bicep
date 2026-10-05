@description('Name of the Function App')
param functionAppName string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Resource ID of the subnet used for Function App VNet integration')
param integrationSubnetResourceId string

@description('Client ID of the Entra application representing the Function API')
param functionApiClientId string

@description('Identifier URI of the Entra application representing the Function API')
param functionApiIdentifierUri string

@description('Principal ID of the Logic App managed identity')
param logicAppPrincipalId string

@description('Name of the Storage Account used by ClinicWorks')
param storageAccountName string

@description('Name of the Blob container used by ClinicWorks')
param storageContainerName string

@description('Document Intelligence endpoint')
param documentIntelligenceEndpoint string

@description('Name of the Key Vault containing ClinicWorks secrets')
param keyVaultName string

// --------------------------------------------------
// Derived values
// --------------------------------------------------

var keyVaultUrl = 'https://${keyVaultName}.vault.${environment().suffixes.keyvaultDns}'
var azureWebJobsStorageSecretName = 'AzureWebJobsStorage'
var documentIntelligenceKeySecretName = 'AZURE-DOCUMENT-INTELLIGENCE-KEY'
var groqApiKeySecretName = 'GROQ-API-KEY'
var databaseUrlSecretName = 'DATABASE-URL'

// --------------------------------------------------
// App Service Plan
// --------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags

  sku: {
    name: 'B1'
  }

  kind: 'linux'

  properties: {
    reserved: true
  }
}

// --------------------------------------------------
// Function App
// --------------------------------------------------

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: tags

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    serverFarmId: appServicePlan.id

    siteConfig: {
      linuxFxVersion: 'Python|3.12'

      appSettings: [
        // ------------------------------------------
        // Azure Functions runtime
        // ------------------------------------------
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }

        // ------------------------------------------
        // Storage configuration
        // ------------------------------------------
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: storageContainerName
        }

        // ------------------------------------------
        // AzureWebJobsStorage
        //
        // Secret is stored in Key Vault.
        // ------------------------------------------
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${azureWebJobsStorageSecretName})'
        }

        // ------------------------------------------
        // Document Intelligence
        // ------------------------------------------
        {
          name: 'AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT'
          value: documentIntelligenceEndpoint
        }
        {
          name: 'AZURE_DOCUMENT_INTELLIGENCE_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${documentIntelligenceKeySecretName})'
        }

        // ------------------------------------------
        // Groq
        // ------------------------------------------
        {
          name: 'GROQ_MODEL'
          value: 'openai/gpt-oss-120b'
        }
        {
          name: 'GROQ_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${groqApiKeySecretName})'
        }

        // ------------------------------------------
        // PostgreSQL
        // ------------------------------------------
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${databaseUrlSecretName})'
        }

        // ------------------------------------------
        // Key Vault
        // ------------------------------------------
        {
          name: 'KEY_VAULT_URL'
          value: keyVaultUrl
        }

        // ------------------------------------------
        // Application Insights
        // ------------------------------------------
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

// --------------------------------------------------
// Function App VNet Integration
// --------------------------------------------------

resource functionAppVnetIntegration 'Microsoft.Web/sites/networkConfig@2025-03-01' = {
  name: 'virtualNetwork'
  parent: functionApp

  properties: {
    subnetResourceId: integrationSubnetResourceId
    swiftSupported: true
  }
}

// --------------------------------------------------
// App Service Authentication / Entra ID
// --------------------------------------------------

resource functionAuth 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'authsettingsV2'
  parent: functionApp

  properties: {
    platform: {
      enabled: true
    }

    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
    }

    identityProviders: {
      azureActiveDirectory: {
        enabled: true

        registration: {
          clientId: functionApiClientId
          openIdIssuer: '${environment().authentication.loginEndpoint}${subscription().tenantId}/v2.0'
        }

        validation: {
          allowedAudiences: [
            functionApiClientId
            functionApiIdentifierUri
          ]

          defaultAuthorizationPolicy: {
            allowedPrincipals: {
              identities: [
                logicAppPrincipalId
              ]
            }
          }
        }
      }
    }

    httpSettings: {
      requireHttps: true
    }
  }
}

// --------------------------------------------------
// Outputs
// --------------------------------------------------

output functionAppName string = functionApp.name

output functionPrincipalId string = functionApp.identity.principalId

output functionAppId string = functionApp.id
