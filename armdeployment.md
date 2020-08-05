---
title: ARMDeployment
layout: template
filename: armdeployment
---

## <b>Breakdown of ARM Deployment to Setup Azure DevOps</b>
To understand the first of the two major deployments in the WVD QuickStart (for an overview, please see <a href="concepts">Concepts</a> section), the ARM deployment that configures the Azure DevOps automation and deploys some supporting resources, let's dive into the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/deploy.json" target="_blank">ARM template</a> itself.

### <b>Parameters</b>
In the parameters section of the ARM template, you'll find all the parameters that are exposed to the user input. ALl of these parameters come with a description to indicate what they're used for. These are typically pretty straightforward and will not be explained further in this documentation.
```
"parameters": {
    "utcValue": {
        "type": "string",
        "metadata": {
            "description": "Please leave this value as '[utcNow()]', as this is used to generate unique names in the deployment. This is a requirement for resources like a keyvault or storage account."
        },
        "defaultValue": "[utcNow()]"
    },
    "existingVnetName": {
        "type": "string",
        "metadata": {
            "description": "The name of the virtual network the VMs will be connected to."
        }
    },
    ....
    ....
}
```

### <b>Variables</b>
The variables section holds certain values that are used throughout the deployment, that are not exposed to the user. As these are less obvious, their meaning and use will be explained in this section.
```
"variables": {
    "_artifactsLocation": "https://raw.githubusercontent.com/samvdjagt/wvdquickstart/master",
```
The *artifactslocation* variable holds the URL to the GitHub repository that is used throughout the deployment to fetch required files. If you are to customize the solution in your own GitHub repository, you should provide the link to it here to make sure the deployment fetches the files from your repo. This repo has to be public for the deployment to work.
```
    "AdminPasswordSecret": "adminPassword",
```
The *AdminPasswordSecret* variable holds the name of the Keyvault secret in which the password of the domain join service account will be stored.
```
    "existingDomainUsername": "[first(split(parameters('DomainJoinAccountUPN'), '@'))]",
    "existingDomainName": "[split(parameters('DomainJoinAccountUPN'), '@')[1]]",
```
The *existingDomainUsername* and *existingDomainName* variables are both taken from the domain join service account UPN, where the domain name is used to perform the domain join of the virtual machines.
```
    "identityName": "WVDServicePrincipal",
```
The *identityName* variable holds the name of the managed identity that will be deployed in this template. This managed identity is then used to run certain deployment scripts.
```
    "location": "[resourcegroup().location]",
    "rgName": "[resourcegroup().name]",
```
The *location* variable will hold the location in which all WVD resources will be deployed. The *rgName* or resource group name holds the name of the resource group in which you're deploying.
```
    "keyvaultName": "[concat('keyvault', parameters('utcValue'))]",
    "assetsName": "[concat('aset', toLower(parameters('utcValue')))]",
    "profilesName": "[concat('prof', toLower(parameters('utcValue')))]",
    "autoAccountName": "[concat('auto', toLower(parameters('utcValue')))]",
```
The above variables hold the names of resources deployed in this template that require a unique identifier, in this case being a Keyvault, two Storage Accounts (the assets storage, which will hold the Modules/ARM folder, and the profiles storage for FSLogix), and an Automation Account.
```
    "tenantId": "[subscription().tenantId]",
```
The *tenantId* variable holds the ID of your AAD tenant.
```
    "jobGuid0": "[guid(toLower(uniquestring(variables('identityName'), resourceGroup().id, parameters('utcValue'),'credentials')))]",
    "jobGuid": "[guid(toLower(uniquestring(variables('identityName'), resourceGroup().id, parameters('utcValue'),variables('autoAccountName'))))]",
    "jobGuid2": "[guid(toLower(uniquestring(variables('identityName'), subscription().id, parameters('utcValue'),'devOpsSetup')))]",
```
The above variables are used to create unique names for the runbook jobs that will be executed in this ARM deployment. The *jobGuid* variables hold the unique guids of the three jobs that will be run.
```
    "devOpsName": "WVDQuickStart0715",   
    "devOpsProjectName": "WVDQuickStart0715",
```
The above variables contain the name of the DevOps organization (*devOpsName*) and the DevOps project that will be created in this deployment.
```
    "targetGroup": "WVDTestUsers",
```
The *targetGroup* variable holds the name of the user group that will be assigned to the WVD environment.
```
    "automationVariables": [
        {
            "name": "subscriptionid",
            "value": "[concat('\"',subscription().subscriptionId,'\"')]"
        },
        {
            "name": "accountName",
            "value": "[concat('\"',variables('autoAccountName'),'\"')]"
        },
        ....
        ....
    ]   
},
```
The *automationVariables* section, which is not shown in full here, contains a list of variables and parameters that will be saved as variables in the Automation account that is created in this deployment. These variables will be accessed by the runbook scripts to generate the appropriate parameter files for the WVD deployment.

### <b>Resources</b>
In this section, the Resources section of the ARM template will be explained piece by piece, showcasing exactly which resources will be deployed and with what objective.
```
"resources": [
    {
        "type": "Microsoft.ManagedIdentity/userAssignedIdentities",
        "name": "[variables('identityName')]",
        "apiVersion": "2018-11-30",
        "location": "[variables('location')]",
        "properties": {}
    },
```
#### Automation Account
The first resource deployed in this template is a Managed Identity that will be used to run deployment scripts later in this template. This resource will, by default, appear as "WVDServicePrincipal" in your deployment's resource group.
```
    {
        "type": "Microsoft.Automation/automationAccounts",
        "apiVersion": "2015-01-01-preview",
        "name": "[variables('autoAccountName')]",
        "location": "[resourceGroup().location]",
        "dependsOn": [
        ],
        "tags": {},
        "properties": {
            "sku": {
                "name": "Free"
            }
        },
```
This section deploys an Automation Account. This automation account is used for a total of three runbooks, all executing custom scripts. These three runbooks are explained below, one by one, and they are part of the automation account deployment.
```
        "resources": [
            {
                "type": "credentials",
                "apiVersion": "2015-01-01-preview",
                "name": "AzureCredentials",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]"
                ],
                "tags": {},
                "properties": {
                    "userName": "[parameters('azureAdminUpn')]",
                    "password": "[parameters('azureAdminPassword')]"
                }
            },
            {
                "type": "credentials",
                "apiVersion": "2015-01-01-preview",
                "name": "domainJoinCredentials",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]"
                ],
                "tags": {},
                "properties": {
                    "userName": "[parameters('DomainJoinAccountUPN')]",
                    "password": "[parameters('DomainJoinAccountPassword')]"
                }
            },
```
The above part of the Automation Account deployment creates two Automation credentials, saving both the Azure Admin credentials and the domain join service account credentials entered by the user for later access by the runbook scripts to authenticate.
```
             {
                "type": "runbooks",
                "apiVersion": "2015-01-01-preview",
                "name": "checkCredentialsRunbook",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/credentials/AzureCredentials')]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/credentials/domainJoinCredentials')]"
                ],
                "tags": {},
                "properties": {
                    "runbookType": "PowerShell",
                    "logProgress": false,
                    "logVerbose": false,
                    "publishContentLink": {
                        "uri": "[concat(variables('_artifactsLocation'),'/ARMRunbookScripts/checkCredentials.ps1')]",
                        "version": "1.0.0.0"
                    }
                } 
            },
            {
                "type": "jobs",
                "apiVersion": "2015-01-01-preview",
                "name": "[variables('jobGuid0')]",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/runbooks/checkCredentialsRunbook')]"
                ],
                "tags": {
                    "key": "value"
                },
                "properties": {
                    "runbook": {
                        "name": "checkCredentialsRunbook"
                    }
                }
            },
The first runbook above runs the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/configureMSI.ps1" target="_blank">configureMSI.ps1</a> script. This is a script that configures the 'WVDServicePrincipal' managed identity in the deployment resource group to give it the *contributor* role on the subscription. This is needed to run deployment scripts in the ARM template successfully.
```
            {
                "type": "runbooks",
                "apiVersion": "2015-01-01-preview",
                "name": "ServicePrincipalRunbook",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/credentials/AzureCredentials')]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/credentials/domainJoinCredentials')]"
                ],
                "tags": {},
                "properties": {
                    "runbookType": "PowerShell",
                    "logProgress": false,
                    "logVerbose": false,
                    "publishContentLink": {
                        "uri": "[concat(variables('_artifactsLocation'),'/ARMRunbookScripts/createServicePrincipal.ps1')]",
                        "version": "1.0.0.0"
                    }
                }
            },
            {
                "type": "jobs",
                "apiVersion": "2015-01-01-preview",
                "name": "[variables('jobGuid')]",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/runbooks/ServicePrincipalRunbook')]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/runbooks/checkCredentialsRunbook')]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/', variables('jobGuid0'))]"
                ],
                "tags": {
                    "key": "value"
                },
                "properties": {
                    "runbook": {
                        "name": "ServicePrincipalRunbook"
                    }
                }
            },
```
The second runbook runs the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/createServicePrincipal.ps1" target="_blank">createServicePrincipal.ps1</a> script. This script creates the AAD application service principal used to create a service connection between the Azure subscription and the DevOps project. If the application already exists, this script will update the existing one with the right permissions.
```
            {
                "type": "runbooks",
                "apiVersion": "2015-01-01-preview",
                "name": "devOpsSetupRunbook",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('microsoft.visualstudio/account/', variables('devOpsName'))]"
                ],
                "tags": {},
                "properties": {
                    "runbookType": "PowerShell",
                    "logProgress": false,
                    "logVerbose": false,
                    "publishContentLink": {
                        "uri": "[concat(variables('_artifactsLocation'),'/ARMRunbookScripts/devopssetup.ps1')]",
                        "version": "1.0.0.0"
                    }
                }
            },
            {
                "type": "jobs",
                "apiVersion": "2015-01-01-preview",
                "name": "[variables('jobGuid2')]",
                "location": "[resourceGroup().location]",
                "dependsOn": [
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/',variables('jobGuid'))]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/runbooks/devOpsSetupRunbook')]",
                    "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/', variables('jobGuid0'))]",
                    "[concat('microsoft.visualstudio/account/', variables('devOpsName'))]",
                    "[concat('Microsoft.Resources/Deployments/userCreation')]"
                ],
                "tags": {
                    "key": "value"
                },
                "properties": {
                    "runbook": {
                        "name": "devOpsSetupRunbook"
                    }
                }
            }
        ]
    },
```
The third and last runbook runs the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/devopssetup.ps1" target="_blank">devopssetup.ps1</a> script. This script makes a number of REST API calls to create a DevOps project, a service connection between the Azure Subscription and the DevOps project, to initialize the DevOps repository with all the required files, to set some permissions in DevOps, and to generate the main automation parameter files: appliedParmeters.psd1 and variables.yml. These two parameter files will be used by the DevOps pipeline to deploy the WVD resources.
```
    {
        "type": "Microsoft.Automation/automationAccounts/variables",
        "apiVersion": "2015-10-31",
        "name": "[concat(variables('autoAccountName'), '/', variables('automationVariables')[copyIndex()].name)]",
        "dependsOn": [
            "[resourceId('Microsoft.Automation/automationAccounts', variables('autoAccountName'))]"
        ],
        "tags": {},
        "properties": {
            "value": "[variables('automationVariables')[copyIndex()].value]"
        },
        "copy": {
            "name": "variableLoop",
            "count": "[length(variables('automationVariables'))]"
        }
    },
```
The above section deploys the Automation variables previously mentioned in the *variables* section of this web page. These variables are accessed by the runbook scripts.

#### Keyvault
```
    {
        "type": "Microsoft.KeyVault/vaults",
        "apiVersion": "2019-09-01",
        "name": "[variables('keyvaultName')]",
        "location": "[variables('location')]",
        "properties": {
            "enabledForDeployment": true,
            "enabledForTemplateDeployment": true,
            "enabledForDiskEncryption": true,
            "enableSoftDelete": true,
            "lockForDeletion": false,
            "tenantId": "[variables('tenantId')]",
            "accessPolicies": [
            ],
            "sku": {
                "name": "Standard",
                "family": "A"
            },
            "secretsObject": {
                "value": {
                    "secrets": []
                }
            }
        },
        "dependsOn": [
           "[concat('Microsoft.Resources/deploymentScripts', '/checkAzureCredentials')]"
        ],
        "resources": [
        ]
    },
    {
        "type": "Microsoft.KeyVault/vaults/secrets",
        "apiVersion": "2015-06-01",
        "name": "[concat(variables('keyvaultName'), '/', variables('AdminPasswordSecret'))]",
        "properties": {
            "name": "[variables('AdminPasswordSecret')]",
            "value": "[parameters('DomainJoinAccountPassword')]"
        },
        "dependsOn": [
            "[concat('Microsoft.KeyVault/vaults/', variables('keyvaultName'))]"
        ]
    },
```
This section deploys a Keyvault, as well as a secret that holds the password to the Azure Admin account. This secret will later be accessed by the DevOps pipeline when deploying the WVD virtual machines.

#### DevOps Organization
```
    {
        "name": "[variables('devOpsName')]",
        "type": "microsoft.visualstudio/account",
        "location": "centralus",
        "apiVersion": "2014-04-01-preview",
        "properties": {
          "operationType": "Create",
          "accountName": "[variables('devOpsName')]"
        },
        "dependsOn": [
            "[concat('Microsoft.Resources/deploymentScripts', '/checkAzureCredentials')]"
        ],
        "resources": []
    },
```
The above section creates the DevOps organization that will host the WVD deployment pipeline.

#### Custom Deployment Scripts
```
    {
        "type": "Microsoft.Resources/deploymentScripts",
        "apiVersion": "2019-10-01-preview",
        "name": "createDevopsPipeline",
        "location": "[variables('location')]",
        "dependsOn": [
            "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/', variables('jobGuid2'))]"
        ],
        "kind": "AzureCLI",
        "identity": {
            "type": "userAssigned",
            "userAssignedIdentities": {
                "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', variables('identityName'))]": {}
            }
        },
        "properties": {
            "forceUpdateTag": 1,
            "azCliVersion": "2.0.80",
            "arguments": "[concat(variables('devOpsName'), ' ', variables('devOpsProjectName'), ' ', parameters('azureAdminUpn'), ' ', parameters('azureAdminPassword'), ' ', 'true')]",
            "primaryScriptUri": "[concat(variables('_artifactsLocation'),'/ARMRunbookScripts/createDevopsPipeline.sh')]",
            "timeout": "PT30M",
            "cleanupPreference": "OnSuccess",
            "retentionInterval": "P1D"
        }
    },
```
The above deployment script *createDevopspipeline* executes the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/createDevopsPipeline.sh" target="_blank">createDevopsPipeline.sh</a> script. This Azure CLI script creates and starts a DevOps pipeline in the newly created DevOps project.
```
    {
        "type": "Microsoft.Resources/deploymentScripts",
        "apiVersion": "2019-10-01-preview",
        "name": "checkAzureCredentials",
        "location": "[variables('location')]",
        "dependsOn": [
            "[concat('Microsoft.ManagedIdentity/userAssignedIdentities/', variables('identityName'))]",
            "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/', variables('jobGuid0'))]"
        ],
        "kind": "AzurePowerShell",
        "identity": {
            "type": "UserAssigned",
            "userAssignedIdentities": {
                "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', variables('identityName'))]": {}
            }
        },
        "properties": {
            "forceUpdateTag": 1,
            "azPowerShellVersion": "3.0",
            "timeout": "PT30M",
            "arguments": "[concat('-username ', parameters('azureAdminUpn'), ' -password ', parameters('azureAdminPassword'))]",
            "primaryScriptUri": "[concat(variables('_artifactsLocation'),'/ARMRunbookScripts/checkAzureCredentials.ps1')]",
            "cleanupPreference": "OnSuccess",
            "retentionInterval": "P1D"
        }
    },
```
The above deployment script *checkAzureCredentials* executes the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/checkAzureCredentials.ps1" target="_blank">checkAzureCredentials.ps1</a> script. This script makes sure that the entered Azure Admin credentials are correct. 
```
    {
        "type": "Microsoft.Resources/deployments",
        "apiVersion": "2019-10-01",
        "name": "userCreation",
        "dependsOn": [
            "[concat('Microsoft.ManagedIdentity/userAssignedIdentities/', variables('identityName'))]",
            "[concat('Microsoft.Automation/automationAccounts/', variables('autoAccountName'), '/jobs/', variables('jobGuid0'))]"
        ],
        "resourceGroup": "[parameters('virtualNetworkResourceGroupName')]",
        "subscriptionId": "[subscription().subscriptionId]",
        "condition": "[equals(parameters('identityApproach'), 'AD')]",
        "properties": {
        "mode": "Incremental",
        "template": {
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {},
            "variables": {},
            "resources": [
            {
                "type": "Microsoft.Compute/virtualMachines/extensions",
                "apiVersion": "2019-12-01",
                "name": "[concat(parameters('computerName'),'/', 'userCreation')]",
                "location": "[resourcegroup().location]",
                "dependsOn": [
                ],
                "properties": {
                    "publisher": "Microsoft.Compute",
                    "type": "CustomScriptExtension",
                    "typeHandlerVersion": "1.7",
                    "autoUpgradeMinorVersion": true,
                    "settings": {
                        "fileUris": [
                            "[concat(variables('_artifactsLocation'), '/Modules/ARM/UserCreation/scripts/createUsers.ps1')]"
                        ],
                        "commandToExecute": "[concat('powershell.exe -ExecutionPolicy Unrestricted -File createUsers.ps1 ', variables('existingDomainName'), ' ', variables('targetGroup'), ' ', variables('_artifactsLocation'))]"
                    }
                }
            }
            ]
        }
```
The above deployment script is ran only in the case of a Native AD deployment (versus Azure AD DS), and it runs a custom script extension on the domain controller VM to create a new user to be assigned to the WVD environment. This custom script extension will execute the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM/UserCreation/scripts/createUsers.ps1" target="_blank">createUsers.ps1</a> script to, by default, create an AD user group, an AD user, assign that user to the group, and start a sync cycle to synchronize these changes with Azure.
