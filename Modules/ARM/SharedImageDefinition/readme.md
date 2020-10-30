# Shared Image Definition

This module deploys an Image Definition in a Shared Image Gallery.

## Resources

- Microsoft.Compute/galleries/images

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `imageDefinitionName` | string | | | Required. Name of the image definition.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `galleryName` | string | | | Required. Name of the Azure Shared Image Gallery
| `osType` | string | `Windows` | `Windows` or `Linux` | Optional. OS type of the image to be created.
| `osState` | string | `Generalized` | `Generalized` or `Specialized` | Optional. This property allows the user to specify whether the virtual machines created under this image are 'Generalized' or 'Specialized'.
| `publisher` | string | `MicrosoftWindowsServer` | | Optional. The name of the gallery Image Definition publisher.
| `offer` | string | `WindowsServer` | | Optional. The name of the gallery Image Definition offer.
| `sku` | string | `2019-Datacenter` | | Optional. The name of the gallery Image Definition SKU.
| `minRecommendedvCPUs` | int | `1` | `1-128` | Optional. The minimum number of the CPU cores recommended for this image.
| `maxRecommendedvCPUs` | int | `4` | `1-128` | Optional. The maximum number of the CPU cores recommended for this image.
| `minRecommendedMemory` | int | `4` | `1-4000` | Optional. The minimum amount of RAM in GB recommended for this image.
| `maxRecommendedMemory` | int | `16` | `1-4000` | Optional. The maximum amount of RAM in GB recommended for this image.
| `hyperVGeneration` | string | `V1` | `V1` or `V2` | Optional. The hypervisor generation of the Virtual Machine. Applicable to OS disks only. - V1 or V2
| `imageDefinitionDescription` | string | | | Optional. The description of this gallery Image Definition resource. This property is updatable.
| `eula` | string | | | Optional. The Eula agreement for the gallery Image Definition. Has to be a valid URL.
| `privacyStatementUri` | string | | | Optional. The privacy statement uri. Has to be a valid URL.
| `releaseNoteUri` | string | | | Optional. The release note uri. Has to be a valid URL.
| `productName` | string | | | Optional. The product ID.
| `planName` | string | | | Optional. The plan ID.
| `planPublisherName` | string | | | Optional. The publisher ID.
| `endOfLife` | string | | | Optional. The end of life date of the gallery Image Definition. This property can be used for decommissioning purposes. This property is updatable. Allowed format: 2020-01-10T23:00:00.000Z
| `excludedDiskTypes` | array | | | Optional. List of the excluded disk types. E.g. Standard_LRS
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
| `imageDefinitionResourceId` | The Resource Id of the Shared Image Definition.
| `imageDefinitionName` | The Name of the Shared Image Definition.

## Considerations

*N/A*

## Additional resources

- [Shared Image Galleries overview](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/shared-image-galleries)
- [Microsoft.Compute galleries/images template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-07-01/galleries/images)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
