# Virtual Machines

This module deploys one or multiple Virtual Machines.

## Resources

- Microsoft.Network/publicIPAddresses
- Microsoft.Network/publicIPAddresses/providers/diagnosticSettings
- Microsoft.Network/publicIPAddresses/providers/locks
- Microsoft.Network/networkInterfaces
- Microsoft.Network/networkInterfaces/providers/diagnosticSettings
- Microsoft.Network/publicIPAddresses/providers/locks
- Microsoft.Compute/availabilitySets
- Microsoft.Compute/virtualMachineScaleSets
- Microsoft.Compute/proximityPlacementGroups
- Microsoft.Compute/virtualMachines
- Microsoft.Compute/virtualMachines/providers/locks
- Microsoft.Compute/virtualMachines/extensions

## Parameters

| Parameter Name| Type| Default Value| Possible values| Description |
| :-- | :-- | :-- | :-- | :-- |
| `vmNames` | array || | Optional. Name(s) of the virtual machine(s). If no explicit names are provided, VM name(s) will be generated based on the vmNamePrefix, vmNumberOfInstances and vmInitialNumber parameters.|
| `vmNamePrefix`| string| `[take(toLower(uniqueString(resourceGroup().name)),10)]` | | Optional. If no explicit values were provided in the vmNames parameter, this prefix will be used in combination with the vmNumberOfInstances and the vmInitialNumber parameters to create unique VM names. You should use a unique prefix to reduce name collisions in Active Directory. If no value is provided, a 10 character long unique string will be generated based on the Resource Group's name. |
| `vmNumberOfInstances`| int | 1| 1-800 | Optional. If no explicit values were provided in the vmNames parameter, this parameter will be used to generate VM names, using the vmNamePrefix and the vmInitialNumber values.|
| `vmInitialNumber` | int | 1| | Optional. If no explicit values were provided in the vmNames parameter, this parameter will be used to generate VM names, using the vmNamePrefix and the vmNumberOfInstances values.|
| `location`| string| `[resourceGroup().location]`| | Optional. Location for all resources.|
| `vmSize`| string| `Standard_D2s_v3` | | Optional. Specifies the size for the VMs. |
| `imageReference`| object| {} | Complex structure, see below.| Optional. OS image reference. In case of marketplace images, it's the combination of the publisher, offer, sku, version attributes. In case of custom images it's the resource ID of the custom image. |
| `plan`| object| {} | Complex structure, see below.| Optional. Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use.|
| `osDisk`| object|| Complex structure, see below.| Required. Specifies the OS disk. |
| `dataDisks` | array | [] | Complex structure, see below.| Optional. Specifies the data disks.|
| `ultraSSDEnabled` | bool| `false`| | Optional. The flag that enables or disables a capability to have one or more managed data disks with UltraSSD_LRS storage account type on the VM or VMSS. Managed disks with storage account type UltraSSD_LRS can be added to a virtual machine or virtual machine scale set only if this property is enabled. |
| `adminUsername` | securestring|| | Required. Administrator username.|
| `adminPassword` | securestring| `""` | | Optional. When specifying a Windows Virtual Machine, this value should be passed. |
| `customData`| securestring| `""` | | Optional. Custom data associated to the VM, this value will be automatically converted into base64 to account for the expected VM format. |
| `windowsConfiguration` | object| {} | Complex structure, see below.| Optional. Specifies Windows operating system settings on the virtual machine.|
| `linuxConfiguration`| object| {} | Complex structure, see below.| Optional. Specifies Linux operating system settings on the virtual machine.|
| `certificatesToBeInstalled`| array | [] | | Optional. Specifies set of certificates that should be installed onto the virtual machine.|
| `allowExtensionOperations` | bool| `true` | | Optional. Specifies whether extension operations should be allowed on the virtual machine. This may only be set to False when no extensions are present on the virtual machine. |
| `requireGuestProvisionSignal`| bool| `false`| | Optional. Specifies whether the guest provision signal is required from the virtual machine.|
| `availabilitySetName`| string| `""` | | Optional. Creates an availability set with the given name and adds the VMs to it. Cannot be used in combination with availability zone nor scale set.|
| `availabilitySetFaultDomain` | int | `2`| | Optional. The number of fault domains to use. |
| `availabilitySetUpdateDomain`| int | `5`| | Optional. The number of update domains to use.|
| `availabilitySetSku`| string| `"Aligned"`| | Optional. Sku of the availability set. Use 'Aligned' for virtual machines with managed disks and 'Classic' for virtual machines with unmanaged disks.|
| `scaleSetName`| string| `""` | | Optional. Creates a virtual machine scale set with the given name and adds the VMs to it. Cannot be used in combination with availability zone nor availability set.|
| `scaleSetFaultDomain`| int | `2`| | Optional. Fault Domain count for each placement group.|
| `proximityPlacementGroupName`| string| `""` | | Optional. Creates an proximity placement group and adds the VMs to it. |
| `proximityPlacementGroupType`| string| `"Standard"` | Standard/Ultra | Optional. Specifies the type of the proximity placement group. |
| `useAvailabilityZone`| bool| `false`| | Optional. Creates an availability zone and adds the VMs to it. Cannot be used in combination with availability set nor scale set. |
| `subnetId`| string|| | Required. Full qualified subnet Id.|
| `vmIPAddress` | string| `""` | | Optional. IP address used as initial IP address. If left empty, the VM will use the next available IP. |
| `enablePublicIP`| bool| `false`| | Optional. Enables the creation of a Public IP and assigns it to the Network Interface.|
| `enableIPForwarding`| bool| `false`| | Optional. Indicates whether IP forwarding is enabled on this network interface.|
| `enableAcceleratedNetworking`| bool| `false`| | Optional. If the network interface is accelerated networking enabled.|
| `loadBalancerBackendPoolId`| string| `""` | | Optional. Represents a Load Balancer backend pool resource identifier, if left blank, no Load Balancer will be associated to the VMSS.|
| `applicationSecurityGroupId` | string| `""` | | Optional. Application Security Group to associate to the Network Interface. If left empty, the Network Interface would not be associated to any Application Security Group. |
| `vmPriority`| string| `"Regular"`| Regular/Low | Optional. Specifies the priority for the virtual machine. |
| `enableEvictionPolicy` | bool| `false`| | Optional. Specifies the eviction policy for the low priority virtual machine. Will result in 'Deallocate' eviction policy.|
| `maxPriceForLowPriorityVm` | string| `""` | | Optional. Specifies the maximum price you are willing to pay for a low priority VM/VMSS. This price is in US Dollars.|
| `dedicatedHostId` | string| `""` | | Optional. Specifies resource Id about the dedicated host that the virtual machine resides in. |
| `licenseType` | string| `""` | Windows_Client/Windows_Server/"" | Optional. Specifies that the image or disk that is being used was licensed on-premises. This element is only used for images that contain the Windows Server operating system.|
| `enableMicrosoftAntiMalware` | bool| `false`| | Optional. Enables Microsoft Windows Defender AV.|
| `microsoftAntiMalwareSettings` | object| {} | Complex structure, see below.| Optional. Settings for Microsoft Windows Defender AV extension.|
| `enableWindowsMMA-Agent` | bool| `false`| | Optional. Specifies if MMA agent for Windows VM should be enabled. If true `workspaceId` should also be specified|
| `enableLinuxMMA-Agent` | bool| `false`| | Optional. Specifies if MMA agent for Linux VM should be enabled. If true `workspaceId` should also be specified|
| `enableWindowsDependency-Agent`| bool| `false`| | Optional. Specifies if Azure Dependency Agent for Windows VM should be enabled. Requires WindowsMMA-Agent to be enabled. |
| `enableLinuxDependency-Agent`| bool| `false`| | Optional. Specifies if Azure Dependency Agent for Linux VM should be enabled. Requires LinuxMMA-Agent to be enabled. |
| `enableNetworkWatcherWindows`| bool| `false`| | Optional. Specifies if Azure Network Watcher Agent for Windows VM should be enabled.|
| `enableNetworkWatcherLinux`| bool| `false`| | Optional. Specifies if Azure Network Watcher Agent for Linux VM should be enabled.|
| `enableWindowsDiskEncryption`| bool| `false`| | Optional. Specifies if Windows VM disks should be encrypted. If enabled, boot diagnostics must be enabled as well. |
| `enableLinuxDiskEncryption`| bool| `false`| | Optional. Specifies if Linux VM disks should be encrypted. If enabled, boot diagnostics must be enabled as well. |
| `diskKeyEncryptionAlgorithm` | string| `"RSA-OAEP"` | RSA-OAEP/RSA-OAEP-256/RSA1_5 | Optional. Specifies disk key encryption algorithm.|
| `keyEncryptionKeyURL`| string| `""` | | Optional. URL of the KeyEncryptionKey used to encrypt the volume encryption key.|
| `keyVaultUri` | string| `""` | | Optional. URL of the Key Vault instance where the Key Encryption Key (KEK) resides. |
| `keyVaultId`| string| `""` | | Optional. Resource identifier of the Key Vault instance where the Key Encryption Key (KEK) resides. |
| `diskEncryptionVolumeType` | string| `"All"`| OS/Data/All | Optional. Type of the volume OS or Data to perform encryption operation|
| `windowsScriptExtensionFileData` | array | [] | Complex structure, see below | Optional. Array of objects that specifies URIs and the storageAccountId of the scripts that need to be downloaded and run by the Custom Script Extension on a Windows VM. |
| `windowsScriptExtensionCommandToExecute` | securestring| "" | | Optional. Specifies the command that should be run on a Windows VM.|
| `forceUpdateTag`| string| `"1.0"`| | Optional. Pass in an unique value like a GUID everytime the operation needs to be force run.|
| `resizeOSDisk`| bool| `false`| | Optional. Should the OS partition be resized to occupy full OS VHD before splitting system volume.|
| `dnsSettings` | array | `[]` | | Optional. List of DNS servers IP addresses. Use empty array to inherit VNet settings|
| `backupVaultName` | string| `""` | | Optional. Recovery service vault name to add VMs to backup.|
| `backupVaultResourceGroup` | string| `""` | | Optional. Resource group of the backup recovery service vault. |
| `backupPolicyName`| string| `""` | | Optional. Backup policy the VMs should be using for backup.|
| `domainName`| string| `""` | | Optional. Specifies the FQDN the of the domain the VM will be joined to. Currently implemented for Windows VMs only. |
| `domainJoinUser`| string| `""` | | Mandatory if domainName is specified. User used for the Domain join operation. Format: username@domainFQDN.|
| `domainJoinPassword`| Secure String | `""` | | Mandatory if domainName is specified. Password of the user specified in domainJoinUser parameter|
| `domainJoinOU`| string| `""` | | Optional. OU where to store the computer account for the domain joined |
| `domainJoinRestart` | bool| `false`| | Optional. Controls the restart of vm after executing domain join |
| `domainJoinOptions` | int | `3`| | Optional. Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx |
| `dscConfiguration`| object| `{}` | Complex structure, see below.| Optional. The DSC configuration object|
| `enableBootDiagnostics`| bool| `false`| | Optional. Whether boot diagnostics should be enabled on the Virtual Machine. |
| `bootDiagnosticStorageAccountName` | string| `` | | Optional. Storage account used to store boot diagnostic information. |
| `diagnosticLogsRetentionInDays`| int | `365`| | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely. |
| `diagnosticStorageAccountId` | string| "" | | Optional. Resource identifier of the Diagnostic Storage Account. |
| `workspaceId` | string| "" | | Optional. Resource identifier of Log Analytics. Mandatory if `enableWindowsMMA-Agent` or `enableLinuxMMA-Agent` is true|
| `eventHubAuthorizationRuleId`| string| "" | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.|
| `eventHubName`| string| "" | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. |
| `lockForDeletion` | bool| `true` | | Optional. Switch to lock Virtual Machine from deletion. |
| `tags`| object| {} | Complex structure, see below.| Optional. Tags of the resource. |
| `baseTime`| string| `[utcNow('u')]` | | Generated. Do not provide a value! This date value is used to generate a registration token. |
| `sasTokenValidityLength`| string| `PT8H` | | Optional. SAS token validity length to use to download files from storage accounts. Usage: 'PT8H' - valid for 8 hours; 'P5D' - valid for 5 days; 'P1Y' - valid for 1 year. When not provided, the SAS token will be valid for 8 hours. |

### Parameter Usage: `imageReference`

#### Marketplace images

```json
"imageReference": {
    "value": {
        "publisher": "MicrosoftWindowsServer",
        "offer": "WindowsServer",
        "sku": "2016-Datacenter",
        "version": "latest"
    }
}
```

#### Custom images

```json
"imageReference": {
    "value": {
        "id": "/subscriptions/12345-6789-1011-1213-15161718/resourceGroups/rg-name/providers/Microsoft.Compute/images/imagename"
    }
}
```

### Parameter Usage: `plan`

```json
"plan": {
    "value": {
        "name": "qvsa-25",
        "product": "qualys-virtual-scanner",
        "publisher": "qualysguard"
    }
}
```

### Parameter Usage: `osDisk`

```json
 "osDisk": {
    "value": {
        "createOption": "fromImage",
        "diskSizeGB": "128",
        "managedDisk": {
            "storageAccountType": "Premium_LRS"
        }
    }
}
```

### Parameter Usage: `dataDisks`

```json
"dataDisks": {
    "value": [{
        "caching": "ReadOnly",
        "createOption": "Empty",
        "diskSizeGB": "256",
        "managedDisk": {
            "storageAccountType": "Premium_LRS"
        }
    },
    {
        "caching": "ReadOnly",
        "createOption": "Empty",
        "diskSizeGB": "128",
        "managedDisk": {
            "storageAccountType": "Premium_LRS"
        }
    }]
}
```

### Parameter Usage: `windowsConfiguration`

```json
"windowsConfiguration": {
    "provisionVMAgent": "boolean",
    "enableAutomaticUpdates": "boolean",
    "timeZone": "string",
    "additionalUnattendContent": [
        {
        "passName": "OobeSystem",
        "componentName": "Microsoft-Windows-Shell-Setup",
        "settingName": "string",
        "content": "string"
        }
    ],
    "winRM": {
        "listeners": [
        {
            "protocol": "string",
            "certificateUrl": "string"
        }
        ]
    }
}
```

### Parameter Usage: `linuxConfiguration`

```json
"linuxConfiguration": {
    "disablePasswordAuthentication": "boolean",
    "ssh": {
        "publicKeys": [
        {
            "path": "string",
            "keyData": "string"
        }
        ]
    },
    "provisionVMAgent": "boolean"
    },
    "secrets": [
    {
        "sourceVault": {
        "id": "string"
        },
        "vaultCertificates": [
        {
            "certificateUrl": "string",
            "certificateStore": "string"
        }
        ]
    }
    ],
    "allowExtensionOperations": "boolean",
    "requireGuestProvisionSignal": "boolean"
}
```

### Parameter Usage: `microsoftAntiMalwareSettings`

```json
"microsoftAntiMalwareSettings": {
    "AntimalwareEnabled": true,
    "Exclusions": {
        "Extensions": ".log;.ldf",
        "Paths": "D:\\IISlogs;D:\\DatabaseLogs",
        "Processes": "mssence.svc"
    },
    "RealtimeProtectionEnabled": true,
    "ScheduledScanSettings": {
        "isEnabled": "true",
        "scanType": "Quick",
        "day": "7",
        "time": "120"
    }
}
```

### Parameter Usage: `windowsScriptExtensionFileData`

```json
"windowsScriptExtensionFileData": {
    "value": [
        //storage accounts with SAS token requirement
        {
            "uri": "https://storageAccount.blob.core.windows.net/wvdscripts/File1.ps1",
            "storageAccountId": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rgName/providers/Microsoft.Storage/storageAccounts/storageAccountName"
        },
        {
            "uri": "https://storageAccount.blob.core.windows.net/wvdscripts/File2.ps1",
            "storageAccountId": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rgName/providers/Microsoft.Storage/storageAccounts/storageAccountName"
        },
        //storage account with public container (no SAS token is required) OR other public URL (not a storage account)
        {
            "uri": "https://github.com/myProject/File3.ps1",
            "storageAccountId": ""
        }
    ]
}
```

### Parameter Usage: `dscConfiguration`

```json
"dscConfiguration": {
    "value": {
        "settings": {
            "wmfVersion": "latest",
            "configuration": {
                "url": "http://validURLToConfigLocation",
                "script": "ConfigurationScript.ps1",
                "function": "ConfigurationFunction"
            },
            "configurationArguments": {
                "argument1": "Value1",
                "argument2": "Value2"
            },
            "configurationData": {
                "url": "https://foo.psd1"
            },
            "privacy": {
                "dataCollection": "enable"
            },
            "advancedOptions": {
                "forcePullAndApply": false,
                "downloadMappings": {
                    "specificDependencyKey": "https://myCustomDependencyLocation"
                }
            }
        },
        "protectedSettings": {
            "configurationArguments": {
                "mySecret": "PasswordValue1"
            },
            "configurationUrlSasToken": "?g!bber1sht0k3n",
            "configurationDataUrlSasToken": "?dataAcC355T0k3N"
        }
    }
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

No outputs

## Considerations

*N/A*

## Additional resources

- [Overview of Windows virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/overview)
- [Microsoft.Compute virtualMachines template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/allversions)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
- [PowerShell DSC Extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-windows#extension-schema)