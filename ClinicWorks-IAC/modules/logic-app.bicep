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

@description('Resource ID of the existing Outlook API connection')
param outlookConnectionId string

@description('Email address that should receive processing failure notifications')
param notificationEmail string


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
        // SUCCESS RESPONSE
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


        // --------------------------------------------------
        // FAILURE NOTIFICATION
        // --------------------------------------------------

        sendFailureNotification: {
          type: 'ApiConnection'

          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'outlook\'][\'connectionId\']'
              }
            }

            method: 'post'

            path: '/v2/Mail'

            body: {
              To: notificationEmail

              Subject: 'ClinicWorks document processing failed'

              Body: '<p>ClinicWorks document processing failed.</p><p><b>Blob:</b> @{triggerBody()?[\'blob_name\']}</p><p><b>Function:</b> ${functionAppName}</p><p>Please check the Logic App and Function App logs for more details.</p>'
            }
          }

          runAfter: {
            callFunction: [
              'Failed'
              'TimedOut'
            ]
          }
        }


        // --------------------------------------------------
        // FAILURE RESPONSE
        // --------------------------------------------------

        failureResponse: {
          type: 'Response'

          kind: 'Http'

          inputs: {
            statusCode: 500

            body: {
              status: 'Failed'

              blob_name: '@triggerBody()?[\'blob_name\']'

              message: 'Document processing failed. Notification has been sent.'
            }
          }

          runAfter: {
            sendFailureNotification: [
              'Succeeded'
            ]
          }
        }
      }

      // ==================================================
      // CONNECTION REFERENCES
      // ==================================================

      outputs: {}
    }

    parameters: {
      '$connections': {
        value: {
          outlook: {
            connectionId: outlookConnectionId
            connectionName: 'outlook'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
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
