# StorageAccount

This module is used to deploy an Azure Storage Account, with resource lock and the ability to deploy 1 or more Blob Containers and 1 or more File Shares. Optional ACLs can be configured on the Storage Account and optional RBAC can be assigned on the Storage Account and on each Blob Container and File Share.

The default parameter values are based on the needs of deploying a diagnostic storage account.

## Resources

- Microsoft.Storage/storageAccounts
- Microsoft.Storage/storageAccounts/providers/locks
- Microsoft.Storage/storageAccounts/blobServices/containers
- Microsoft.Storage/storageAccounts/fileServices/shares

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `storageAccountName` | string | | | Required. Name of the Storage account.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `roleAssignments` | array | [] | Complex structure, see below. | Optional. Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or it's fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'.
| `storageAccountKind` | string | `StorageV2` | Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage | Optional. Type of Storage Account to create.
| `storageAccountSku` | string | `Standard_GRS` | Standard_LRS, Standard_GRS, Standard_RAGRS, Standard_ZRS, Premium_LRS, Premium_ZRS, Standard_GZRS, Standard_RAGZRS | Optional. Storage Account Sku Name.
| `storageAccountAccessTier` | string | `Hot` | Hot, Cool | Optional. Storage Account Access Tier.
| `azureFilesIdentityBasedAuthentication` | object | {} | Complex structure, see below. | Optional. Provides the identity based authentication settings for Azure Files.
| `vNetId` | string | "" | | Optional. Virtual Network Identifier used to create a service endpoint.
| `networkAcls` | object | {} | Complex structure, see below. | Optional. Network ACLs, this value contains IPs to whitelist and/or Subnet information.
| `blobContainers` | array | [] | Complex structure, see below. | Optional. Blob containers to create.
| `fileShares` | array | [] | Complex structure, see below. | Optional. File shares to create.
| `lockForDeletion` | bool | `true` | | Optional. Switch to lock Virtual Network Gateway from deletion.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.
| `cuaId` | string | "" | | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered.
| `sasTokenValidityLength` | string | `PT8H` |  | Optional. SAS token validity length. Usage: 'PT8H' - valid for 8 hours; 'P5D' - valid for 5 days; 'P1Y' - valid for 1 year. When not provided, the SAS token will be valid for 8 hours.
| `baseTime` | string | `[utcNow('u')]` |  | Generated. Do not provide a value! This date value is used to generate a SAS token to access the modules.

### Parameter Usage: `roleAssignments`

```json
"roleAssignments": {
    "value": [
        {
            "roleDefinitionIdOrName": "Storage File Data SMB Share Contributor",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012", // object 1
                "78945612-1234-1234-1234-123456789012" // object 2
            ]
        },
        {
            "roleDefinitionIdOrName": "Reader",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012", // object 1
                "78945612-1234-1234-1234-123456789012" // object 2
            ]
        },
        {
            "roleDefinitionIdOrName": "/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012" // object 1
            ]
        }
    ]
}
```

### Parameter Usage: `azureFilesIdentityBasedAuthentication`

The `azureFilesIdentityBasedAuthentication` parameter accepts a JSON object providing the identity based authentication settings for Azure Files with the "directoryServiceOptions" property to specify the directory service used. Allowed values for that property are "None", "Azure AD DS" or "AD" to respectively disable the identity based access for file shares, enable it for Azure Active Directory Domain Service (AAD DS) or for Active Directory (AD).

In case of AD additional properties are required to be specified in the "activeDirectoryProperties" object as shown in the example below.

#### `None`

Here's an example of specifying no identity based access for file shares (disabled).

```json
"azureFilesIdentityBasedAuthentication": {
    "value": {
        "directoryServiceOptions": "None"
    }
}
```

#### `Azure AD DS`

Here's an example of specifying identity based access for file shares leveraging Azure Active Directory Domain Service (enabled).

```json
"azureFilesIdentityBasedAuthentication": {
    "value": {
        "directoryServiceOptions": "Azure AD DS"
    }
}
```

#### `AD`

Here's an example of specifying identity based access for file shares leveraging Active Directory (enabled).

Additional properties are required in this scenario:

- domainName: the primary domain that the AD DNS server is authoritative for.
- netBiosDomainName: the NetBIOS domain name.
- forestName: the AD forest to get.
- domainGuid: the domain GUID.
- domainSid: the domain security identifier (SID).
- azureStorageSid: the security identifier (SID) for Azure Storage.

```json
"azureFilesIdentityBasedAuthentication": {
    "value": {
        "directoryServiceOptions": "AD",
        "activeDirectoryProperties": {
            "domainName": "contoso.com",
            "netBiosDomainName": "contoso.com",
            "forestName": "contoso.com",
            "domainGuid": "12345678-1234-1234-1234-987654321098",
            "domainSid": "S-1-5-21-1234567890-5678901234-7890123456",
            "azureStorageSid": "S-1-5-21-1234567890-5678901234-7890123456-1111"
      }
    }
}
```

### Parameter Usage: `networkAcls`

```json
"networkAcls": {
    "value": {
        "bypass": "AzureServices",
        "defaultAction": "Deny",
        "virtualNetworkRules": [
            {
                "subnet": "sharedsvcs"
            }
        ],
        "ipRules": []
    }
}
```

### Parameter Usage: `blobContainers`

The `blobContainer` parameter accepts a JSON Array of object with "name" and "publicAccess" properties in each to specify the name of the Blob Containers to create and level of public access (container level, blob level or none). Also RBAC can be assigned at Blob Container level

Here's an example of specifying two Blob Containes. The first named "one" with public access set at container level and RBAC Reader role assigned to two principal Ids. The second named "two" with no public access level and no RBAC role assigned.

```json
"blobContainers": {
    "value": [
        {
            "name": "one",
            "publicAccess": "Container", //Container, Blob, None
            "roleAssignments": [
                {
                    "roleDefinitionIdOrName": "Reader",
                    "principalIds": [
                        "12345678-1234-1234-1234-123456789012", // object 1
                        "78945612-1234-1234-1234-123456789012" // object 2
                    ]
                }
            ]
        },
        {
            "name": "two",
            "publicAccess": "None", //Container, Blob, None
            "roleAssignments": []
        }
    ]
}

```

### Parameter Usage: `fileShares`

The `fileShares` parameter accepts a JSON Array of object with "name" and "shareQuota" properties in each to specify the name of the File Shares to create and the maximum size of the shares, in gigabytes. Also RBAC can be assigned at File Share level.

Here's an example of specifying a single File Share named "one" with 5TB (5120GB) of shareQuota, with "Reader" role assigned to two principal Ids and "Storage File Data SMB Share Contributor" assigned to a third principal Id.

```json
"fileShares": {
    "value": [
        {
            "name": "wvdprofiles",
            "shareQuota": "5120",
            "roleAssignments": [
                {
                    "roleDefinitionIdOrName": "Reader",
                    "principalIds": [
                        "12345678-1234-1234-1234-123456789012", // object 1
                        "78945612-1234-1234-1234-123456789012" // object 2
                    ]
                },
                {
                    "roleDefinitionIdOrName": "Storage File Data SMB Share Contributor",
                    "principalIds": [
                        "56789012-1234-1234-1234-123456789012" // object 3
                    ]
                }
            ]
        }
    ]
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
| :- | :- |
| `storageAccountResourceId` | The Resource id of the Storage Account.
| `storageAccountRegion` | The Region of the Storage Account. |
| `storageAccountName` | The Name of the Storage Account.
| `storageAccountResourceGroup` | The name of the Resource Group the Storage Account was created in.
| `storageAccountSasToken` | The SAS Token for the Storage Account.<br/>The SAS Token generated is set to expire in an amount of time defined by the `sasTokenValidityLength` parameter.
| `storageAccountAccessKey` | The Access Key for the Storage Account.
| `storageAccountPrimaryBlobEndpoint` | The public endpoint of the Storage Account. |
| `blobContainers` | The array of the blob containers created. |
| `fileShares` | The array of the file shares created. |

## Considerations

This is a generic module for deploying a Storage Account. Any customization for different storage needs (such as a diagnostic or other storage account) need to be done through the Archetype.

## Additional resources

- [Introduction to Azure Storage](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction)
- [ARM Template format for Microsoft.Storage/storageAccounts](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-06-01/storageaccounts)
- [Storage Account Sku Type options](https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.storage.fluent.storageaccountskutype?view=azure-dotnet)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
