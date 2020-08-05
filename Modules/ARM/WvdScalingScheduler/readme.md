# Workflows

This module deploys an Azure Logic App Workflow for WVD.

## Resources

- Microsoft.Logic/workflows

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `logicAppName` | | The name of the logic app to create |
| `location` | `[resourceGroup().location]` | Location for all resources |
| `webhookURI` | | Webhook URI of Logic App |
| `recurrenceInterval` | | Specifies the recurrence interval of the job in minutes |
| `actionSettingsBody` | | Specifies the body in Action settings ('Note': Input should be in json format) |
| `diagnosticLogsRetentionInDays` | `365` | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `lockForDeletion` | `true` | Optional. Switch to lock Logic App from deletion.
| `tags` | | Optional. Tags of the Logic App resource.


### Parameter Usage: `logicAppName`

The name of the logic app to create.

```json
"logicAppName": {
    "value": "wvdScalingApp"
}
```

### Parameter Usage: `location`

Location for all resources.

```json
"location": {
    "value": "westeurope"
}
```

### Parameter Usage: `webhookURI`

Webhook URI of Logic App.

```json
"webhookURI": {
    "value": "https://s2events.azure-automation.net/webhooks?token=3WW50Nvq2nFYfUihjxHSrtgehutDBhdliuwfANviPLo%3d"
}
```

### Parameter Usage: `recurrenceInterval`

Specifies the recurrence interval of the job in minutes.

```json
"recurrenceInterval": {
    "value": 15
}
```

### Parameter Usage: `actionSettingsBody`

Specifies the body in Action settings ('Note': Input should be in json format). Contains the data send to the AutomationAccount runbook

```json
"actionSettingsBody": {
    "value": {
        "HostPoolName": "[HostPoolName]", // Mandatory. Name of the host pool to scale
        "AutomationAccountName": "[AutomationAccountName]", // Mandatory. Name of the automation account running the scaling runbook
        "LimitSecondsToForceLogOffUser": "[LimitSecondsToForceLogOffUser]", // Mandatory. Time the user gets to save progress before being logged off
        "EndPeakTime": "[EndPeakTime]", // Mandatory. Desired end time for downscaling
        "BeginPeakTime": "[BeginPeakTime]", // Mandatory. Desired start time for upscaling
        "UtcOffset": "[UtcOffset]", // Mandatory. Offset of the host pool location relative to the automation account location
        "LogOffMessageBody": "[LogOffMessageBody]", // Mandatory. Message for the Log-Off popup
        "LogOffMessageTitle": "[LogOffMessageTitle]", // Mandatory. Title for the Log-Off popup
        "MinimumNumberOfRDSH": 1, // Mandatory. Minimum number of hosts to keep always running
        "SessionThresholdPerCPU": 1, // Mandatory. Desired sessions per CPU. Used to calculate scaling demand
        "subscriptionid": "", // Optional. Subscription of the target host pool
        "AADTenantId": "", // Optional. TenantId of the target host pool
        "ConnectionAssetName": "", // Optional. Name of the automation account runAs connection
        "HostPoolResourceGroup": "", // Optional. Resource group of the target host pool
        "MaintenanceTagName": "", // Optional. Tag for host pools to exclude from scaling
    }
}
```

### Parameter Usage: `diagnosticLogsRetentionInDays`

Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.

```json
"diagnosticLogsRetentionInDays": {
    "value": 30
}
```

### Parameter Usage: `diagnosticStorageAccountId`

Resource identifier of the Diagnostic Storage Account.

```json
"diagnosticStorageAccountId": {
    "value": "/subscriptions/396826c76-d304-46d8-a0f6-718dbded536c/resourceGroups/Base-RG/providers/Microsoft.Storage/storageAccounts/sharedSA"
}
```

### Parameter Usage: `workspaceId`

Resource identifier of Log Analytics.

```json
"workspaceId": {
    "value": "/subscriptions/396826c76-d304-46d8-a0f6-718dbded536c/resourceGroups/Base-RG/providers/microsoft.operationalinsights/workspaces/my-sbx-eu-la"
}
```

### Parameter Usage: `eventHubAuthorizationRuleId`

Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.

```json
"eventHubAuthorizationRuleId": {
    "value": "/subscriptions/396826c76-d304-46d8-a0f6-718dbded536c/resourceGroups/Base-RG/providers/Microsoft.EventHub/namespaces/my-sbx-02-eh/authorizationRules/myRule"
}
```

### Parameter Usage: `eventHubName`

Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.

```json
"eventHubName": {
    "value": "myEventHub"
}
```

### Parameter Usage: `lockForDeletion`

Switch to lock Logic App from deletion.

```json
"lockForDeletion": {
    "value": true
}
```

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

```json
"tags": {
    "value": {
        "Environment": "Non-Prod",
        "Contact": "test.user@testcompany.com",
        "PurchaseOrder": "1234",
        "CostCenter": "7890",
        "ServiceName": "DeploymentValidation",
        "Role": "DeploymentValidation"
    }
}
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `logicAppResourceId` | The Resource Id of the Logic App |
| `logicAppResourceGroup` | The Resource Group the Logic App was deployed to |
| `logicAppName` | The Name of the Log App |

## Considerations

*N/A*

## Additional resources

- [An introduction to Logic Apps](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [ARM template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.logic/2016-06-01/workflows)