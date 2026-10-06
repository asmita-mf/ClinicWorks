@description('Name of the Document Intelligence resource')
param resourceName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: resourceName
  location: location
  tags: tags

  kind: 'FormRecognizer'

  sku: {
    name: 'S0'
  }

  properties: {
    customSubDomainName: resourceName
    publicNetworkAccess: 'Enabled'
  }
}

output documentIntelligenceName string = documentIntelligence.name
output documentIntelligenceId string = documentIntelligence.id
output documentIntelligenceEndpoint string = documentIntelligence.properties.endpoint

@secure()
output documentIntelligenceKey string = documentIntelligence.listKeys().key1
