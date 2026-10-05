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

@description('Azure Blob API connection resource ID')
param azureBlobConnectionId string

@description('Azure Blob API connection name')
param azureBlobConnectionName string

@description('Blob container name')
param storageContainerName string


resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags

  // System-assigned identity:
  // Logic App -> Azure Blob connection
  //
  // User-assigned identity:
  // Logic App -> Function App
  identity: {
    type: 'SystemAssigned, UserAssigned'

    userAssignedIdentities: {
      '${logicAppIdentityId}': {}
    }
  }

  properties: {
    state: 'Enabled'

    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'

      contentVersion: '1.0.0.0'

      // ==================================================
      // CONNECTION PARAMETERS
      // ==================================================

      parameters: {
        '$connections': {
          type: 'Object'
          defaultValue: {}
        }
      }

      // ==================================================
      // HTTP TRIGGER
      // ==================================================

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

      // ==================================================
      // ACTIONS
      // ==================================================

      actions: {

        // --------------------------------------------------
        // CREATE SAS URL
        // --------------------------------------------------

        createSasUri: {
          type: 'ApiConnection'

          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }

            method: 'post'

            path: '/v2/datasets/@{encodeURIComponent(\'AccountNameFromSettings\')}/CreateSharedLinkByPath'

            body: {
              Permissions: 'Read'

              ExpiryTime: '@formatDateTime(addHours(utcNow(), 1), \'yyyy-MM-ddTHH:mm:ssZ\')'

              AccessProtocol: 'HttpsOnly'

              Path: '@concat(\'${storageContainerName}/\', triggerBody()?[\'blob_name\'])'
            }
          }

          runAfter: {}
        }


        // --------------------------------------------------
        // CALL FUNCTION APP
        // --------------------------------------------------

        callFunction: {
          type: 'Http'

          inputs: {
            method: 'POST'

            uri: 'https://${functionAppName}.azurewebsites.net/api/process-document'

            queries: {
              blob_name: '@{triggerBody()?[\'blob_name\']}'
            }

            headers: {
              'Content-Type': 'application/json'
            }

            authentication: {
              type: 'ManagedServiceIdentity'

              identity: logicAppIdentityId

              audience: 'https://${functionAppName}.azurewebsites.net'
            }
          }

          runAfter: {
            createSasUri: [
              'Succeeded'
            ]
          }
        }


        // --------------------------------------------------
        // RETURN FUNCTION RESPONSE
        // --------------------------------------------------

        response: {
          type: 'Response'

          kind: 'Http'

          inputs: {
            statusCode: 200

            body: {
              status: 'Success'

              blob_name: '@triggerBody()?[\'blob_name\']'

              function_response: '@body(\'callFunction\')'
            }
          }

          runAfter: {
            callFunction: [
              'Succeeded'
            ]
          }
        }
      }
    }

    // ==================================================
    // API CONNECTION REFERENCES
    // ==================================================

    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: azureBlobConnectionId

            connectionName: azureBlobConnectionName

            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }

            id: subscriptionResourceId(
              'Microsoft.Web/locations/managedApis',
              location,
              'azureblob'
            )
          }
        }
      }
    }
  }
}


// ==================================================
// OUTPUTS
// ==================================================

output logicAppName string = logicApp.name

output logicAppId string = logicApp.id

output systemAssignedPrincipalId string = logicApp.identity.principalId
