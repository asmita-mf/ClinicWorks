@description('Name of the Key Vault')
param keyVaultName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location

  tags: tags

  properties: {
    tenantId: subscription().tenantId

    sku: {
      family: 'A'
      name: 'standard'
    }

    enableRbacAuthorization: true

    enabledForTemplateDeployment: false
  }
}


output keyVaultName string = keyVault.name

output keyVaultId string = keyVault.id