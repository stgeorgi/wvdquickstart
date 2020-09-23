# User Assigned Identities

This module deploys User Assigned Identities, with resource lock.

## Resources

- Microsoft.ManagedIdentity/userAssignedIdentities
- Microsoft.ManagedIdentity/userAssignedIdentities/providers/locks

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `userMsiName` | string | `[guid(resourceGroup().id)` | | Optional. Name of the User Assigned Identity.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
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
| `msiName` | The name of the User Assigned Identity. |
| `msiResourceId` | The Resource Id of the User Assigned Identity. |
| `msiPrincipalId` | The Principal Id of the User Assigned Identity. |
| `msiResourceGroup` | The name of the Resource Group the User Assigned Identity was created in. |

## Considerations

*N/A*

## Additional resources

- [What are managed identities for Azure resources?](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [Microsoft.ManagedIdentity resource types](https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/allversions)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)