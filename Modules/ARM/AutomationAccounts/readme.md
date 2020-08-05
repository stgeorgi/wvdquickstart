# AutomationAccounts

This module deploys an Azure Automation Account, with resource lock.

## Resources

- Microsoft.Automation/automationAccounts
- Microsoft.Automation/automationAccounts/runbooks
- Microsoft.Automation/automationAccounts/providers/locks
- Microsoft.Automation/automationAccounts/schedules
- Microsoft.Automation/automationAccounts/jobSchedules
- Microsoft.Automation/automationAccounts/providers/diagnosticsettings

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `cuaId` | string | | | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered
| `automationAccountName` | string | | | Required. Name of the Azure Automation Account
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `skuName` | string | `Basic` | `Free`, `Basic`  | Optional. Specifies the SKU for the Automation Account
| `runbooks` | array | [] | | Optional. List of runbooks to be created in the automation account. Complex structure, see below.
| `schedules` | array | [] | | Optional. List of schedules to be created in the automation account. Complex structure, see below.
| `jobSchedules` | array | [] | | Optional. List of jobSchedules to be created in the automation account. Complex structure, see below.
| `baseTime` | string | [utcNow('u')] | | Optional. Time used as a basis for e.g. the schedule start date |
| `diagnosticLogsRetentionInDays` | int | `365` | | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string | | | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string | | | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string | | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string | | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `lockForDeletion` | bool | `true` | | Optional. Switch to lock Automation Account from deletion.
| `tags` | object | | | Optional. Tags of the Automation Account resource.

### Parameter Usage: `automationAccountName`

Name of the Azure Automation Account

```json
"automationAccountName": {
    "value": "wvd-scaling-autoaccount"
}
```

### Parameter Usage: `location`

Location for all resources.

```json
"location": {
    "value": "westeurope"
}
```

### Parameter Usage: `skuName`

Specifies the SKU for the Automation Account

```json
"skuName": {
    "value": "Basic"
}
```

### Parameter Usage: `runbooks`

List of runbooks to be created in the automation account

```json
"runbooks": {
    "value": [
        {
            "runbookName": "ScalingRunbook", // Name for a runbook if you intent to deploy one
            "runbookType": "PowerShell", // Type of script
            "runbookScriptUri": "https://raw.githubusercontent.com/Azure/basicScale.ps1", // The uri where the runbook script is located
            "runbookScriptLocationSasToken": "?sv=2019-10-10&ss=bfqt&srt=sco&sp=rwdlacup&se=2020-05-02T00:26:37Z&st=2020-05-01T16:26:37Z&spr=https&sig=71%2BwSSu%2FdT8ZyqeOvk%2BjImr7xoqD7thwfqDYIY7nLRA%3D", // The sasToken required to access runbookScriptLocation when they're located in a storage account with private access
            "version": "1.0.0.0" // version of api
        }
    ]
}
```

### Parameter Usage: `schedules`

List of schedules to be created in the automation account

```json
"schedules": {
    "value": [
        {
            "scheduleName": "ScalingRunbook_Schedule", // The schedule name.
            "startTime": "", // Gets or sets the start time of the schedule.
            "expiryTime": "9999-12-31T23:59:00+00:00", // Gets or sets the end time of the schedule.
            "interval": 15, // Gets or sets the interval of the schedule. 
            "frequency": "Minute", // Gets or sets the frequency of the schedule. - OneTime, Day, Hour, Week, Month, Minute
            "timeZone": "Europe/Berlin", // Gets or sets the time zone of the schedule.
            "advancedSchedule": "" // Gets or sets the AdvancedSchedule
        }
    ]
}
```

### Parameter Usage: `jobSchedules`

List of jobSchedules to be created in the automation account

```json
"jobSchedules": {
    "value": [
        {
            "jobScheduleName": "ScalingRunbook_JobSchedule", // jobSchedule used to generate unique id
            "scheduleName": "ScalingRunbook_Schedule", // Gets or sets the schedule
            "runbookName": "ScalingRunbook", // Gets or sets the runbook
            "parameters": { // Gets or sets a list of job properties.
                "param1": "value1"
            },
            "runOn": "" // Gets or sets the hybrid worker group that the scheduled job should run on.
        }
    ]
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
| `automationAccountResourceId` | The Resource Id of the Automation Account.
| `automationAccountResourceGroup` | The Resource Group the Automation Account was deployed to.
| `automationAccountName` | The Name of the Automation Account.

## Considerations

*N/A*

## Additional resources

- [An introduction to Azure Automation](https://docs.microsoft.com/en-us/azure/automation/automation-intro)
- [Microsoft.Automation automationAccounts template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.automation/allversions)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)