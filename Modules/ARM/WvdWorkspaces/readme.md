# WVD Workspaces

This module deploys WVD Workspaces, with resource lock and diagnostic configuration.

## Resources

- Microsoft.DesktopVirtualization/workspaces
- Microsoft.DesktopVirtualization/workspaces/providers/diagnosticsettings
- Microsoft.DesktopVirtualization/workspaces/providers/locks

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `workSpaceName` | string | | | Required. The name of the Workspace to be attach to new Application Group.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `appGroupResourceIds` | array | [] | | Required. Resource IDs fo the existing Application groups this workspace will group together.
| `workspaceFriendlyName` | string | "" | | Optional. The friendly name of the Workspace to be created.
| `workspaceDescription` | string | "" |  | Optional. The description of the Workspace to be created.
| `diagnosticLogsRetentionInDays` | int | `365` | | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string | "" | | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string | "" | | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string | "" | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string | "" | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `lockForDeletion` | bool | `true` | | Optional. Switch to lock the resource from deletion.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the resource.
| `cuaId` | string | "" | | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered

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
| `workspaceResourceId` | The Resource Id of the WVD Workspace. |
| `workspaceResourceGroup` | The name of the Resource Group the WVD Workspace was created in. |
| `workspaceName` | The Name of the Workspace. |

## Considerations

*N/A*

## Additional resources

- [What is Windows Virtual Desktop?](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview)
- [Windows Virtual Desktop environment](https://docs.microsoft.com/en-us/azure/virtual-desktop/environment-setup)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)