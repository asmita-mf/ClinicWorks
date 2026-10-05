@description('Application Insights resource ID')
param appInsightsResourceId string

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceResourceId string

@description('Application Insights resource name')
param appInsightsName string

@description('Log Analytics workspace resource name')
param logAnalyticsWorkspaceName string

@description('Azure region')
param location string

@description('Common resource tags')
param tags object

@description('Email address for Azure Monitor alert notifications')
param alertEmail string

@description('Resource ID of the backend App Service')
param appServiceResourceId string

@description('Backend health endpoint URL')
param healthCheckUrl string

@description('Number of geographic locations allowed to fail before availability alert fires')
param availabilityFailedLocationCount int = 2

// ============================================================
// EXISTING MONITORING RESOURCES
//
// Application Insights and Log Analytics are created by
// app-insights.bicep.
//
// This module only references them and creates monitoring
// resources such as alerts, action groups, and availability
// tests.
// ============================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

// ============================================================
// ACTION GROUP
// ============================================================

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${appInsightsName}'
  location: 'global'

  properties: {
    groupShortName: 'ClinicMon'
    enabled: true

    emailReceivers: [
      {
        name: 'PrimaryEmail'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// ============================================================
// AVAILABILITY TEST
//
// GET /api/health
// Every 5 minutes
// Multiple geographic locations
// Expected HTTP 200
// ============================================================

resource healthAvailabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: 'webtest-${appInsightsName}-health'
  location: location

  tags: {
    'hidden-link:${appInsights.id}': 'Resource'
  }

  properties: {
    SyntheticMonitorId: 'webtest-${appInsightsName}-health'
    Name: 'ClinicWorks API Health Check'
    Enabled: true

    // 300 seconds = 5 minutes
    Frequency: 300

    // Maximum response time in seconds
    Timeout: 120

    Kind: 'standard'

    RetryEnabled: true

    // Geographic test locations
    Locations: [
      {
        Id: 'us-ca-sjc-azr'
      }
      {
        Id: 'us-va-ash-azr'
      }
      {
        Id: 'emea-fr-pra-edge'
      }
      {
        Id: 'apac-sg-sin-azr'
      }
      {
        Id: 'emea-ru-msa-edge'
      }
    ]

    Request: {
      RequestUrl: healthCheckUrl
      HttpVerb: 'GET'
    }

    ValidationRules: {
      ExpectedHttpStatusCode: 200
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

// ============================================================
// AVAILABILITY ALERT
//
// Alert when 2 or more geographic locations fail
// ============================================================

resource availabilityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${appInsightsName}-availability'
  location: 'global'

  properties: {
    description: 'Alert when ClinicWorks API health check fails from multiple geographic locations'
    severity: 2
    enabled: true

    scopes: [
      healthAvailabilityTest.id
      appInsights.id
    ]

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'

      webTestId: healthAvailabilityTest.id
      componentId: appInsights.id
      failedLocationCount: availabilityFailedLocationCount
    }

    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ============================================================
// CPU ALERT
//
// CPU > 80% for 5 minutes
// ============================================================

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${appInsightsName}-cpu-high'
  location: 'global'

  properties: {
    description: 'Alert when backend App Service CPU usage is above 80 percent for 5 minutes'
    severity: 2
    enabled: true

    scopes: [
      appServiceResourceId
    ]

    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'

    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'

      allOf: [
        {
          name: 'HighCpu'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'CpuPercentage'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }

    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ============================================================
// MEMORY ALERT
//
// Memory > 80% for 5 minutes
// ============================================================

resource memoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${appInsightsName}-memory-high'
  location: 'global'

  properties: {
    description: 'Alert when backend App Service memory usage is above 80 percent for 5 minutes'
    severity: 2
    enabled: true

    scopes: [
      appServiceResourceId
    ]

    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'

    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'

      allOf: [
        {
          name: 'HighMemory'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'MemoryPercentage'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }

    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ============================================================
// HTTP 5XX ALERT
//
// Alert when backend App Service returns HTTP 5xx errors
// ============================================================

resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${appInsightsName}-http5xx'
  location: 'global'

  properties: {
    description: 'Alert when backend App Service returns HTTP 5xx errors'
    severity: 2
    enabled: true

    scopes: [
      appServiceResourceId
    ]

    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'

    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'

      allOf: [
        {
          name: 'Http5xxErrors'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Http5xx'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
        }
      ]
    }

    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ============================================================
// UNHANDLED EXCEPTIONS
// ============================================================

resource unhandledExceptionAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-unhandled-exceptions'
  location: location

  properties: {
    description: 'Alert when unhandled application exceptions are detected'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            exceptions
            | where timestamp >= ago(5m)
            | summarize ExceptionCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// DEPENDENCY FAILURES
//
// Covers:
// - Blob Storage
// - PostgreSQL
// - Document Intelligence
// - Groq / AI
// - Other dependencies
// ============================================================

resource dependencyFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-dependency-failure'
  location: location

  properties: {
    description: 'Alert when application dependencies fail'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp >= ago(5m)
            | where success == false
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// FUNCTION PROCESSING ERRORS
//
// Looks for:
// - Error processing document
// - Processing failed
// - Blob Trigger Error
// ============================================================

resource functionProcessingErrorAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-function-processing-errors'
  location: location

  properties: {
    description: 'Alert when Function document processing errors are logged'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            traces
            | where timestamp >= ago(5m)
            | where message contains "Error processing document"
                or message contains "Processing failed"
                or message contains "Blob Trigger Error"
            | summarize ErrorCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// DOCUMENT FAILED STATUS
// ============================================================

resource documentFailedAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-document-failed'
  location: location

  properties: {
    description: 'Alert when document processing status is FAILED'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            traces
            | where timestamp >= ago(5m)
            | where message contains "FAILED"
            | where message contains "document"
            | summarize FailedDocuments = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// DOCUMENT NEEDS REVIEW
// ============================================================

resource documentNeedsReviewAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-document-needs-review'
  location: location

  properties: {
    description: 'Alert when document processing requires manual review'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            traces
            | where timestamp >= ago(5m)
            | where message contains "NEEDS_REVIEW"
            | summarize ReviewCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// LOW AI CONFIDENCE
//
// Confidence < 80%
//
// Assumes the application logs confidence as a numeric
// custom property named "confidence_score".
// ============================================================

resource lowConfidenceAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-low-confidence'
  location: location

  properties: {
    description: 'Alert when AI document extraction confidence is below 80 percent'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            customEvents
            | where timestamp >= ago(5m)
            | extend confidence = todouble(customDimensions["confidence_score"])
            | where isnotnull(confidence)
            | where confidence < 80
            | summarize LowConfidenceCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// POSTGRESQL CONNECTION FAILURES
// ============================================================

resource postgresConnectionFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-postgres-connection-failure'
  location: location

  properties: {
    description: 'Alert when PostgreSQL dependency connections fail'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp >= ago(5m)
            | where success == false
            | where target contains "postgres"
                or target contains "postgresql"
                or name contains "postgres"
                or name contains "postgresql"
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// BLOB STORAGE DEPENDENCY FAILURES
// ============================================================

resource blobDependencyFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-blob-failure'
  location: location

  properties: {
    description: 'Alert when Blob Storage dependency calls fail'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp >= ago(5m)
            | where success == false
            | where target contains "blob"
                or target contains "storage"
                or name contains "blob"
                or name contains "storage"
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// DOCUMENT INTELLIGENCE DEPENDENCY FAILURES
// ============================================================

resource documentIntelligenceFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-document-intelligence-failure'
  location: location

  properties: {
    description: 'Alert when Document Intelligence dependency calls fail'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp >= ago(5m)
            | where success == false
            | where target contains "cognitiveservices"
                or target contains "document"
                or name contains "document"
                or name contains "analyze"
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// AI / GROQ DEPENDENCY FAILURES
// ============================================================

resource aiDependencyFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-ai-failure'
  location: location

  properties: {
    description: 'Alert when AI or Groq dependency calls fail'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      appInsights.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp >= ago(5m)
            | where success == false
            | where target contains "groq"
                or target contains "openai"
                or target contains "llm"
                or name contains "groq"
                or name contains "openai"
                or name contains "llm"
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// LOGIC APP / ORCHESTRATION ERRORS
//
// This query assumes Logic App diagnostic data is being sent
// to the Log Analytics workspace.
// ============================================================

resource logicAppFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-${appInsightsName}-logic-app-failure'
  location: location

  properties: {
    description: 'Alert when Logic App orchestration failures are detected'
    severity: 2
    enabled: true

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    scopes: [
      logAnalyticsWorkspace.id
    ]

    criteria: {
      allOf: [
        {
          query: '''
            AzureDiagnostics
            | where TimeGenerated >= ago(5m)
            | where ResourceProvider == "MICROSOFT.LOGIC"
            | where status_s == "Failed"
            | summarize FailureCount = count()
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }

    autoMitigate: true
  }
}

// ============================================================
// OUTPUTS
// ============================================================

output appInsightsName string = appInsights.name
output appInsightsId string = appInsights.id

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

output actionGroupName string = actionGroup.name
output actionGroupId string = actionGroup.id

output availabilityTestName string = healthAvailabilityTest.name
output availabilityTestId string = healthAvailabilityTest.id
