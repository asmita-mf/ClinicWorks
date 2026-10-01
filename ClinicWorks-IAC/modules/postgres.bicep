@description('Name of the PostgreSQL Flexible Server')
param serverName string

@description('Azure region')
param location string

@description('PostgreSQL administrator username')
param administratorLogin string

@secure()
@description('PostgreSQL administrator password')
param administratorLoginPassword string

@description('Common resource tags')
param tags object

@description('Resource ID of the delegated PostgreSQL subnet')
param delegatedSubnetResourceId string

@description('Resource ID of the PostgreSQL Private DNS Zone')
param privateDnsZoneArmResourceId string

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  tags: tags

  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }

  properties: {
    version: '18'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword

    storage: {
      storageSizeGB: 32
    }

    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }

    highAvailability: {
      mode: 'Disabled'
    }

    network: {
        delegatedSubnetResourceId: delegatedSubnetResourceId
        privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
        publicNetworkAccess: 'Disabled'
    }
  }
}

output postgresServerName string = postgresServer.name
output postgresServerId string = postgresServer.id