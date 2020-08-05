---
title: Customize
layout: template
filename: customize
---

## <b>How To Customize the WVD QuickStart</b>
While many of the parameters for a QuickStart WVD deployment are set to defaults to simplify the process, you can modify your deployment any way you want. Most customizations can be completed directly in the repository of the DevOps project created in the initial ARM deployment, as will be explained below. However, for more advanced customizations, including modification of the inital ARM deployment, you can also clone this GitHub repository as will be explained at the bottom of this page.

You can find your DevOps repository by navigating to <a href="https://dev.azure.com" target="_blank">Azure DevOps</a> and by clicking on the project that's there. In the side menu on the left, you will see a button "Repos" where you will find all your files. You can edit files online in DevOps, or create an online copy of this repository using the clone functionality. In the image below, you will see what your repository will look like.
![DevOps Repository](images/devopsRepo.PNG?raw=true)

### <b>Customize the WVD Deployment in DevOps</b>
Customization of the WVD Deployment has been made easy through the curation of two central parameter files that are used in the deployment of all the WVD resources. By simply adapting these files in the repository of your DevOps project (which has been created in the inital ARM deployment), you can fully customize the DevOps pipeline and the resources that are being deployed. Below, we'll go through the two main parameter files that are used in the deployment, appliedParameters.psd1 and variables.yml. Should you want to edit any parameters to customize your deployment, you will most likely do it in those files. When doing so in your DevOps project's repository, be sure to commit the file after changing it and then re-running the entire pipeline for the modifications to have effect.

#### AppliedParameters.psd1
The <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static/appliedParameters.template.psd1" target="_blank">AppliedParameters.psd1</a> file will contain most of the relevant parameters for the WVD deployment. These parameters are generated in the initial ARM deployment and are used by the DevOps automation to deploy WVD resources. You will find this file in your DevOps repo under QS-WVD/static/appliedParameters.psd1 and you can simply edit values here and then rerun the pipeline to change your WVD deployment (NOTE: Some parameters from this file occur in the variables.yml file discussed below. You should change these values in both files). Below is an excerpt of this file - Every parameter comes with a descriptive comment to explain what it's used for.
```
@{
    # General Information #
    # =================== #
    # Environment
    subscriptionId                        = "[subscriptionId]"      # Azure Subscription Id
    tenantId                              = "[tenantId]"            # Azure Active Directory Tenant Id
    objectId                              = "[objectId]"            # Object Id of the serviceprincipal, found in Azure Active Directory / App registrations
  
    # ResourceGroups
    location                              = "eastus"                # Location in which WVD resources will be deployed
    resourceGroupName                     = "[resourceGroupName]"   # Name of the resource group in which WVD resources will be deployed
    ...
    ...
```

#### Variables.yml
The <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/variables.template.yml" target="_blank">variables.yml</a> file will contain some parameters relevant to the WVD deployment and some variables related to the DevOps pipeline functionality. The DevOps pipeline calls on this variable file throughout its functioning and you will find it in the QS-WVD/variables.yml file in your DevOps projects' repository. Below is an excerpt of this file - Every parameter comes with a descriptive comment to explain what it's used for.
```
variables: 

#############
## GENERAL ##
#############
#region general

- name: orchestrationFunctionsPath # Name of folder where some functions are located
  value: SharedDeploymentFunctions

- name: serviceConnection # Name of the service connection between the Azure subscription and DevOps
  value: "WVDServiceConnection"

- name: location 
  value: "[location]"

#endregion

#######################
## PIPELINE SPECIFIC ##
#######################
#region specific

# Jobs
- name: enableJobDeployAssetsStorageAccount # To enable/disable job
  value: true

- name: parameterFolderPath
  value: 'QS-WVD'
...
...
```

#### Parameters that occur in both variables.yml and appliedParameters.psd1
To provide a complete overview of which values you will need to change in both of the parameter files, please find a list below of all the parameter that occur twice. In case of any customization, please make sure to change these values in both files before re-running the pipeline.

* *Location* (Location in which WVD resources will be deployed)
* *domainJoinUserName* (domain controller admin username, taken from domainJoinUser UPN)
* *wvdAssetsStorage* (Name of the assets storage account)
* *resourceGroupName* (Name of the resource group in which WVD resources will be deployed)
* Image-related parameters:
  * *publisher*: MicrosoftWindowsDesktop (default)
  * *offer*: office-365 (default)
  * *sku*: 20h1-evd-o365pp (default, Windows 10 Enterprise Multi-Session, Build 2004 + Office 365 ProPlus)
  * *version*: latest (default)
* *HostPoolName* (Name of WVD host pool)
* *profilesStorageAccountName* (Name of the storage account where user profiles will be stored)
* *identityApproach* (identity approach to use, either a 'Native AD' or Azure Active Directory Domain Services (Azure AD DS) approach)

### Pipeline.yml
For more advanced customization, you can also choose to edit the DevOps pipeline itself. This pipeline can be found in the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/pipeline.yml" target="_blank">pipeline.yml</a> file, which will be stored in your DevOps project's repository under QS-WVD/pipeline.yml. The main reason to modify this file would be to either remove or add a job to the pipeline, or to edit an existing one. In the case of adding a new job, you might find the pipeline.yml files in the Modules/ARM/{moduleName}/Pipeline subfolders useful, as these provide a template for likely any resource you want to deploy in the automation. To support new jobs, you can always add new parameters to the variables.yml file as well. For a more detailed breakdown of the pipeline file, see the <a href="devops" target="_blank">DevOps concepts</a> section.

### <b>Example: Using A Custom VM Image</b>
The WVD QuickStart is not an advanced image management solution, nor does it offer functionality to build a custom image for you. For more information about custom images, feel free to check out the Azure Image Builder and Microsoft Documentation. Once you have a custom image in Azure, it's very easy to use it in the WVD QuickStart to deploy your WVD Virtual Machines with. All you have to do is go into the *variables.yml* file and edit the following section:
```
#customImageReferenceId, as value, put: '/subscriptions/<subscriptionId>/resourceGroups/<image-resource-group-name>/providers/Microsoft.Compute/galleries/<SIG name>/images/<image name>/versions/<version>'
- name: customImageReferenceId
  value: ''
```
By default, the customImageReferenceId is set to an empty string as value. To use your custom image, take the link you see above and replace all the fields enclosed in brackets with your own values. Then put this link as the value for the customImageReferenceId, commit the file in your DevOps project's repository, and run the pipeline. If you've previously deployed with the QuickStart, however, this pipeline will fail when deploying the host pool - Since a host pool can only have one image definition. To avoid this from happening, you either want to delete your previously deployed VMs and remove them from the host pool, or you can change the name of the host pool in both *appliedParameters.psd1* and *variables.yml*. The same goes for the workspace and the desktop app group as for the host pool - you would want to go through the same steps for those two to ensure the pipeline succeeds. Additionally, you do want to make sure that this image is deployed in the same region as your WVD deployment for the pipeline to succeed.

### <b>Advanced: Customize the WVD QuickStart Code</b>
In case the above customization is not sufficient to support your needs, a more advanced customization is possible by editing the source code of the WVD QuickStart yourself, which can be found <a href="https://github.com/samvdjagt/wvdquickstart" target="_blank">here</a>. Before doing any customizations, it is highly recommended to review the <a href="repo" target="_blank">repository structure</a> and the accompanying breakdown of all files. After doing so, you can start customizing by doing the following:

* Clone this repository (https://github.com/samvdjagt/wvdquickstart.git)
* Commit your copy of the repository to a repository in your own account (NOTE: This repository must be public for the automation to work)
* In your repository, go through the files and change all URLs with "samvdjagt/wvdquickstart" in it to point towards your repository. You will have to do this in the following files: *devopssetup.ps1, wvdsessionhost.parameters.template.json, Invoke-GeneralDeployment.ps1,* and the main ARM template's *deploy.json.*. Additionally, for the "Deploy to Azure" button to work properly, you should change the URL in the main Readme.MD.
* You should now be able to customize anything you want. To customize the initial ARM deployment, you can make edits in the main folder's *deploy.json* file.

### <b>Example: Add a Custom Script Extension</b>
In this example, we'll walk through the process of modifying the Custom Script Extensions (CSE) that are installed on the WVD VMs. These steps can be used to either modify an existing CSE, to add a new CSE, or to remove one. As explained in the <a href="repo" target="_blank">repository breakdown</a>, the custom script extensions are located in the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts" target="_blank">Uploads/WVDScripts</a> folder. As you can see there, there are currently four CSEs that are being installed on the VMs. These are also explained in the <a href="repo" target="_blank">repository breakdown</a>. To create a new CSE, you could go ahead and create a folder *005-{CSE-NAME}*. At the very least, this folder will have to contain a *cse_run.ps1* file. To get started with this, it's recommended to take an existing *cse_run.ps1* file from one of the other CSEs. You can reuse most of such a file, all the way to the following line:
```
Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\<CSE-NAME>"
```
Then, you can add any content to your cse_run.ps1 that you want. In case your CSE will need to take some input parameters, you can take a look at how this is done in, for example, the 001-AzFiles CSE. The parameters are loaded from the download file name specified at the top of the script, imported using the following code:
```
LogInfo("###################")
LogInfo("## 0 - LOAD DATA ##")
LogInfo("###################")

$ConfigurationFilePath= Join-Path $PSScriptRoot $ConfigurationFileName

$ConfigurationJson = Get-Content -Path $ConfigurationFilePath -Raw -ErrorAction 'Stop'

try { $FSLogixConfig = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
catch {
    Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
}
```
You can use this code in your CSE to import parameters as well. If these parameters are static, you can simply save them to a .json file in your *005-{CSE-Name}* folder, using the format used, for example in <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static/templates/pipelineinput/fslogix.parameters.template.json" target="_blank">fslogix.parameters.template.json</a>. Should you want to generate the parameters in the DevOps pipeline, for example if they depend on user input, you will have to make a parameter template file just lik that one and save it in the templates/pipelineinput folder. To the DevOps pipeline, you would then have to add a task that copies the parameters for your CSE into your CSE folder:
```
              - task: CopyFiles@2
                name: Copy_{Your-CSE-Name}_parameters
                inputs:
                  SourceFolder: '$(Build.Repository.LocalPath)/QS-WVD/Parameters'
                  Contents: '{Your-CSE-Name}.parameters.json'
                  TargetFolder: '$(Pipeline.Workspace)/s/Uploads/WVDScripts/005-{Your-CSE-Name}'
                  OverWrite: true
```
You can ask this task at the top of your DevOps pipeline (*pipeline.yml* file) where the other *copy* tasks are located.

Apart from the files in the WVDScripts folder, there are a couple of other components to keep in mind. In <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static/templates/pipelineinput/wvdsessionhost.parameters.template.json" target="_blank">wvdsessionhost.parameters.template.json</a>, you will find this section at the bottom of the file:
```
"windowsScriptExtensionFileData": {
            "value": [
                {
                    "uri": "https://[wvdAssetsStorage].blob.core.windows.net/wvdscripts/scriptExtensionMasterInstaller.ps1",
                    "storageAccountId": "/subscriptions/[subscriptionId]/resourceGroups/[resourceGroupName]/providers/Microsoft.Storage/storageAccounts/[wvdAssetsStorage]"
                },
                {
                    "uri": "https://[wvdAssetsStorage].blob.core.windows.net/wvdscripts/001-AzFiles.zip",
                    "storageAccountId": "/subscriptions/[subscriptionId]/resourceGroups/[resourceGroupName]/providers/Microsoft.Storage/storageAccounts/[wvdAssetsStorage]"
                },
                {
                    "uri": "https://[wvdAssetsStorage].blob.core.windows.net/wvdscripts/002-FSLogix.zip",
                    "storageAccountId": "/subscriptions/[subscriptionId]/resourceGroups/[resourceGroupName]/providers/Microsoft.Storage/storageAccounts/[wvdAssetsStorage]"
                },
                {
                    "uri": "https://[wvdAssetsStorage].blob.core.windows.net/wvdscripts/003-NotepadPP.zip",
                    "storageAccountId": "/subscriptions/[subscriptionId]/resourceGroups/[resourceGroupName]/providers/Microsoft.Storage/storageAccounts/[wvdAssetsStorage]"
                },
                {
                    "uri": "https://[wvdAssetsStorage].blob.core.windows.net/wvdscripts/004-Teams.zip",
                    "storageAccountId": "/subscriptions/[subscriptionId]/resourceGroups/[resourceGroupName]/providers/Microsoft.Storage/storageAccounts/[wvdAssetsStorage]"
                }
            ]
        }
```
This specifies which CSEs will be installed on the VMs. In case you want to remove an existing one, you can simply remove it here and it will no longer be installed. If you want to add a new CSE, you will have to provide a link to it here. This link will be exactly the same as the other four, except for the name of the .zip file, which would be *005-{CSE-Name}.zip*.
    
One last step you might have to take is to add some lines to the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/downloads.parameters.json" target="_blank">Uploads/WVDScripts/downloads.parameters.json</a>. This files specifies certain downloads needed for the CSEs - This parameter file specifies the URL from which to download the required file and where to save it. For example, this script specifies from which URL to download FSLogix and the Microsoft Teams MSI package. Should you need any such downloads for your CSE, this would be the place to specify it.

Following all those steps, you should be all set to test your new CSE. Make sure all files are committed to the DevOps repository and then you can go ahead and run the pipeline.
