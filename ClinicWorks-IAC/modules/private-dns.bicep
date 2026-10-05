@description('Name of the Private DNS Zone')
param zoneName string

@description('Common resource tags')
param tags object

@description('Resource ID of the Virtual Network')
param vnetResourceId string

@description('private DNS Zone Name')
param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: privateDnsZoneName
  parent: privateDnsZone
  location: 'global'

  properties: {
    registrationEnabled: false

    virtualNetwork: {
      id: vnetResourceId
    }
  }
}

output privateDnsZoneName string = privateDnsZone.name
output privateDnsZoneId string = privateDnsZone.id
