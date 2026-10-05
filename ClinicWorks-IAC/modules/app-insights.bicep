@description('Name of the Application Insights resource')
param appInsightsName string

@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object


// ============================================================
// LOG ANALYTICS WORKSPACE
// ============================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags

  properties: {
    sku: {
      name: 'PerGB2018'
    }

    retentionInDays: 30
  }
}


// ============================================================
// APPLICATION INSIGHTS
// ============================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'

  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}


// ============================================================
// OUTPUTS
// ============================================================

output appInsightsName string = appInsights.name

output appInsightsId string = appInsights.id

output appInsightsConnectionString string = appInsights.properties.ConnectionString

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
