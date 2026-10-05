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

  // ==================================================
  // IDENTITIES
  // ==================================================
  //
  // User-assigned identity:
  // Logic App -> Function App
  //
  // System-assigned identity:
  // Available to the Logic App itself if required later.
  //
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
      // PARAMETERS
      // ==================================================

      parameters: {}

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

          runAfter: {}
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
  }
}


// ==================================================
// OUTPUTS
// ==================================================

output logicAppName string = logicApp.name

output logicAppId string = logicApp.id

output systemAssignedPrincipalId string = logicApp.identity.principalId
