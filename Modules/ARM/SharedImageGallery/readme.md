# Share Image Gallery

This module deploys Share Image Gallery, with resource lock.

## Resources

- Microsoft.Compute/galleries
- Microsoft.Compute/galleries/locks

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `galleryName` | string | | | Required. Name of the Azure Shared Image Gallery
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `galleryDescription` | string | | | Optional. Description of the Azure Shared Image Gallery
| `lockForDeletion` | bool | `true` | | Optional. Switch to lock resources from deletion.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags for all resources.

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
| `galleryResourceId` | The Resource Id of the Shared Image Gallery.
| `galleryResourceGroup` | The name of the Resource Group the Shared Image Gallery was created in.
| `galleryName` | The Name of the Shared Image Gallery.

## Considerations

*N/A*

## Additional resources

- [Shared Image Galleries overview](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/shared-image-galleries)
- [Microsoft.Compute galleries template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-07-01/galleries)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
