@description('Name of the backend App Service')
param backendAppServiceName string

@description('Name of the frontend App Service')
param frontendAppServiceName string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Azure region')
param location string

@description('App Service Plan SKU')
param skuName string = 'B1'

@description('Common resource tags')
param tags object

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Resource ID of the subnet used for App Service VNet integration')
param integrationSubnetResourceId string

@description('Name of the Storage Account used by ClinicWorks')
param storageAccountName string

@description('Name of the Blob container used by ClinicWorks')
param storageContainerName string

@description('Name of the Key Vault containing ClinicWorks secrets')
param keyVaultName string

// --------------------------------------------------
// App Service Plan
// --------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location

  tags: tags

  sku: {
    name: skuName
  }

  kind: 'linux'

  properties: {
    reserved: true
  }
}


// --------------------------------------------------
// Backend App Service - FastAPI
// --------------------------------------------------

resource backendAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: backendAppServiceName
  location: location

  tags: tags

  kind: 'app,linux'

  properties: {
    serverFarmId: appServicePlan.id

    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'

      appCommandLine: 'gunicorn -k uvicorn.workers.UvicornWorker app.main:app'

      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: storageContainerName
        }
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=DATABASE-URL)'
        }
        {
          name: 'LOGIC_APP_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=LOGIC-APP-URL)'
        }
      ]
    }
  }
}


// --------------------------------------------------
// Backend VNet Integration
// --------------------------------------------------

resource backendAppServiceVnetIntegration 'Microsoft.Web/sites/networkConfig@2025-03-01' = {
  name: 'virtualNetwork'
  parent: backendAppService

  properties: {
    subnetResourceId: integrationSubnetResourceId
    swiftSupported: true
  }
}


// --------------------------------------------------
// Frontend App Service - Streamlit
// --------------------------------------------------

resource frontendAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: frontendAppServiceName
  location: location

  tags: tags

  kind: 'app,linux'

  properties: {
    serverFarmId: appServicePlan.id

    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'

      appCommandLine: 'python -m streamlit run app/main.py --server.address=0.0.0.0 --server.port=8000'

      appSettings: [
        {
          name: 'FASTAPI_BASE_URL'
          value: 'https://${backendAppServiceName}.azurewebsites.net'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}


// --------------------------------------------------
// Frontend VNet Integration
// --------------------------------------------------

resource frontendAppServiceVnetIntegration 'Microsoft.Web/sites/networkConfig@2025-03-01' = {
  name: 'virtualNetwork'
  parent: frontendAppService

  properties: {
    subnetResourceId: integrationSubnetResourceId
    swiftSupported: true
  }
}


// --------------------------------------------------
// Outputs
// --------------------------------------------------

output backendAppServiceName string = backendAppService.name

output backendAppServiceId string = backendAppService.id

output frontendAppServiceName string = frontendAppService.name

output frontendAppServiceId string = frontendAppService.id

output appServicePlanName string = appServicePlan.name
