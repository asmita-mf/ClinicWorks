@description('Name of the App Service')
param appServiceName string

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


resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location

  tags: tags

  kind: 'app,linux'

  properties: {
    serverFarmId: appServicePlan.id

    siteConfig: {
        linuxFxVersion: 'PYTHON|3.12'

        appSettings: [
            {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsightsConnectionString
            }
        ]
    }
  }
}

resource appServiceVnetIntegration 'Microsoft.Web/sites/networkConfig@2025-03-01' = {
  name: 'virtualNetwork'
  parent: appService

  properties: {
    subnetResourceId: integrationSubnetResourceId
    swiftSupported: true
  }
}

output appServiceName string = appService.name

output appServicePlanName string = appServicePlan.name