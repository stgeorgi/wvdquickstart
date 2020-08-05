# EventHub Namespace

This module deploys Resource Groups.

## Resources

The following Resources are deployed.

- Microsoft.Resources/resourceGroups

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `resourceGroupName` | string | | | Required. The name of the Resource Group.
| `location` | string | `[deployment().location]` | | Optional. Location of the Resource Group. It uses the deployment's location when not provided.
| `lockForDeletion` | bool | `true` | | Optional. Switch to lock Event Hub from deletion.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.

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
| `resourceGroupName` | ResourceGroup Name output parameter

## Scripts

- There is no Scripts for this Module

## Considerations

- There is no deployment considerations for this Module

## Additional resources

- [Microsoft Resource Group template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/2019-05-01/resourcegroups)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
