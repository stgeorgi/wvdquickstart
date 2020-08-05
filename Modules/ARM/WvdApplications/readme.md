# WVD Applications

This module deploys WVD Applications.

## Resources

- Microsoft.DesktopVirtualization/applicationGroups/applications

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `applications` | array | {} | Complex structure, see below. | Required. List of applications to be created in the Application Group.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `appGroupName` | string | "" | | Required. Name of the Application Group to create the application(s) in.
| `cuaId` | string | "" | | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered

### Parameter Usage: `applications`

```json
"applications": {
    "value": [
        {
            "name": "notepad",
            "description": "Notepad by ARM template",
            "friendlyName": "Notepad",
            "filePath": "C:\\Windows\\System32\\notepad.exe",
            "commandLineSetting": "DoNotAllow",
            "commandLineArguments": "",
            "showInPortal": true,
            "iconPath": "C:\\Windows\\System32\\notepad.exe",
            "iconIndex": 0
        },
        {
            "name": "wordpad",
            "description": "WordPad by ARM template 2",
            "friendlyName": "WordPad",
            "filePath": "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe",
            "commandLineSetting": "DoNotAllow",
            "commandLineArguments": "",
            "showInPortal": true,
            "iconPath": "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe",
            "iconIndex": 0
        }
    ]
}

## Outputs

| Output Name | Description |
| :-          | :-          |
| `applicationResourceIds` | The list of the application resourceIds deployed. |
| `applicationResourceGroup` | The name of the Resource Group the WVD Applications were created in. |
| `appGroupName` | The Name of the Application Group to register the Application(s) in. |


## Considerations

*N/A*

## Additional resources

- [What is Windows Virtual Desktop?](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview)
- [Windows Virtual Desktop environment](https://docs.microsoft.com/en-us/azure/virtual-desktop/environment-setup)
