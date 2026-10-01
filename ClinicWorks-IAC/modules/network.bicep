@description('Name of the Virtual Network')
param vnetName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }

    subnets: [
      {
        name: 'snet-app'

        properties: {
            addressPrefix: '10.10.1.0/24'

            delegations: [
            {
                name: 'webDelegation'
                properties: {
                serviceName: 'Microsoft.Web/serverFarms'
                }
            }
            ]
        }
      }

      {
        name: 'snet-function'

        properties: {
            addressPrefix: '10.10.2.0/24'

            delegations: [
            {
                name: 'webDelegation'

                properties: {
                serviceName: 'Microsoft.Web/serverFarms'
                }
            }
            ]
        }
      }

      {
        name: 'snet-postgres'
        properties: {
          addressPrefix: '10.10.3.0/24'

          delegations: [
            {
              name: 'postgresDelegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

output vnetName string = vnet.name

output vnetId string = vnet.id

output appSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'snet-app'
)
output postgresSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'snet-postgres'
)
output functionSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'snet-function'
)