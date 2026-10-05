@description('Name of the storage account')
param storageAccountName string

@description('Name of the blob container')
param containerName string

@description('Azure region for the storage account')
param location string

@description('Common resource tags')
param tags object


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location

  tags: tags

  sku: {
    name: 'Standard_LRS'
  }

  kind: 'StorageV2'

  properties: {
    accessTier: 'Hot'
  }
}


resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccount.name}/default/${containerName}'

  properties: {
    publicAccess: 'None'
  }
}


output storageAccountName string = storageAccount.name

output containerName string = containerName

output storageAccountId string = storageAccount.id
