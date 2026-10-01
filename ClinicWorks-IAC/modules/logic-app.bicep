@description('Name of the Logic App')
param logicAppName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

@description('Function App host name')
param functionAppName string

@description('User-assigned managed identity resource ID')
param logicAppIdentityId string

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags

  properties: {
    state: 'Enabled'

    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'

      parameters: {}
      identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${logicAppIdentityId}': {}
        }
      }

      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                blob_name: {
                  type: 'string'
                }
              }
              required: [
                'blob_name'
              ]
            }
          }
        }
      }

      actions: {
        callFunction: {
          type: 'Http'

          inputs: {
            method: 'POST'

            uri: 'https://${functionAppName}.azurewebsites.net/api/process-document'

            queries: {
              blob_name: '@{triggerBody()?[\'blob_name\']}'
            }

            authentication: {
              type: 'ManagedServiceIdentity'
              identity: logicAppIdentityId
              audience: 'https://${functionAppName}.azurewebsites.net'
            }
          }
        }
      }
      
    }

    parameters: {}
  }
}

output logicAppName string = logicApp.name
output logicAppId string = logicApp.id