---
title: Repository
layout: template
filename: repo
---

## <b>Repository Breakdown by file</b>
On this page, you'll find an in-depth breakdown of all the files associated with the WVD QuickStart solution. This is intended for any advanced users who wish to customize the WVD QuickStart for their needs or to do some advanced troubleshooting. The GitHub repository consists of two branches:

* Master branch: All code required by the WVD QuickStart lives here
* gh-pages branch: All files required for the GitHub pages website are located here

The folder structure in the master branch is as follows:

* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts" target="_blank">ARMRunbookScripts</a>: In this folder, a number of custom scripts are located that are run by the ARM deployment, either through an automation runbook or a deployment script.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/static" target="_blank">/static</a>: In this folder, some PowerShell modules required by the above scripts are located
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM" target="_blank">Modules/ARM</a>: This folder contains modular ARM templates that are called by the DevOps automation to deploy Azure resources. For every resource, there's a dedicated deploy.json file, as well as a parameters file, pipeline file, and a testing script. These files are generic and should typically not be modified.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD" target="_blank">QS-WVD</a>: This folder contains many of the files associated with the DevOps pipeline. This folder is also where you'll do most of your customization. The pipeline.yml file is the main DevOps automation pipeline, and the variables.yml file is where the pipeline gets all its parameters. 
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/parameters" target="_blank">/parameters</a>: This folder is populated in the automation to store ARM deployment parameter files. 
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/scripts" target="_blank">/scripts</a>: This folder contains scripts that are called by the DevOps pipeline.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static" target="_blank">/static</a>: This folder contains the important appliedParameters.psd1 file (created in the inital ARM deployment). The parameters in this file are used for the deployment of your WVD resources, and changing the parameters here can be an easy way to customize your WVD deployment.
    * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static/templates/pipelineinput" target="_blank">/templates/pipelineinput</a>: In here, all the ARM parameter file templates are located, which are populated in the automation based on the parameters in appliedParameters.psd1.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions" target="_blank">SharedDeploymentFunctions</a>: This folder contains some scripts called by the DevOps automation pipeline to asssist in the deployment of certain resources.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads" target="_blank">Uploads</a>: This folder contains the Custom Script Extensions that are installed on the newly deployed WVD VMs.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts" target="_blank">/Scripts</a>: This folder contains the four different custom script extensions that are installed: Azure Files enablement, FSLogix configuration, NotepadPlusPlus, and Microsoft Teams installation.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/deploy.json" target="_blank">Deploy.json</a>: This is the ARM template used for the initial DevOps setup deployment.

### <b>ARMRunbookScripts</b>
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/checkAzureCredentials.ps1" target="_blank">checkAzureCredentials.ps1</a>: This script makes sure that the entered Azure Admin credentials are correct. 
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/configureMSI.ps1" target="_blank">configureMSI.ps1</a>: Script that configures the 'WVDServicePrincipal' managed identity in the deployment resource group to give it the *contributor* role on the subscription. This is needed to run deployment scripts in the main ARM template successfully.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/createDevopsPipeline.sh" target="_blank">createDevopsPipeline.sh</a>: This Azure CLI script creates and starts a DevOps pipeline in the newly created DevOps project.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/createServicePrincipal.ps1" target="_blank">createServicePrincipal.ps1</a>: This script creates the AAD application service principal used to create a service connection between the Azure subscription and the DevOps project. If the application already exists, this script will update the existing one with the right permissions.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/devopssetup.ps1" target="_blank">devopssetup.ps1</a>: This script makes a number of REST API calls to create a DevOps project, a service connection between the Azure Subscription and the DevOps project, to initialize the DevOps repository with all the required files, to set some permissions in DevOps, and to generate the main automation parameter files: appliedParmeters.psd1 and variables.yml.

#### <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/ARMRunbookScripts/static" target="_blank">ARMRunbookScripts/static</a>
The azuremodules.zip in this folder contains the following PowerShell modules:
* Az.Accounts
* Az.Automation
* Az.Keyvault
* Az.ManagedServiceIdentity
* Az.Resources
* Az.Websites
* AzureAD
If you want to use additional Powershell modules in your runbook scripts, you can add them to this zip folder and adapt the runbookscripts accordingly to install them.
The other two zip folder contain static files related to WVD SAAS.

### <b>Modules/ARM</b>
Every module in this folder follows the same folder structure:
* /Parameters: parameters file for the ARM template
* /Pipeline: .yml file that can be used to deploy this resource
* /Scripts: Usually empty, unless custom scripts are needed for the deployment of the resource
* /Tests: Script that validates the ARM template syntax
* deploy.json: ARM template used to deploy this resource
* readme.md: Readme for the specific module

One important module is <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM/UserCreation" target="_blank">UserCreation</a>, as this folder contains the script <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM/UserCreation/scripts/createUsers.ps1" target="_blank">createUsers.ps1</a> that is used in Native AD deployments to create a new user in on the domain controller through a custom script extension.

### <b>QS-WVD</b>
This is a crucial folder, as it contains the deployment parameters as well as the DevOps automation files. Directly in the folder you will find the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/pipeline.yml" target="_blank">pipeline.yml</a> and <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/variables.template.yml" target="_blank">variables.template.yml</a> files, which are both further explained <a href="devops" target="_blank">here</a>. The remaining subfolders are explained below.

#### QS-WVD/parameters
While this folder only holds a Readme.MD file, it is used in the automation to store the WVD ARM deployment parameter files, and it should therefore not be deleted.

#### QS-WVD/scripts
This folder contains certain Powershell scripts that are invoked by the DevOps pipeline:

* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/scripts/Invoke-StorageAccountPostDeployment.ps1" target="_blank">Invoke-StorageAccountPostDeployment.ps1</a>: This script is used in the deployment of the Assets storage account (see <a href="devops" target="_blank">DevOps</a> to upload the required files for the WVD Virtual Machine Custom Script Extensions.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/scripts/New-PipelineParameterSetup.ps1" target="_blank">New-PipelineParameterSetup.ps1</a>: This script is called at the beginning of the DevOps pipeline (explained <a href="devops" target="_blank">here</a>) to generate the parameter files for the deployment of WVD resources.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/scripts/Update-WVDHostPool.ps1" target="_blank">Update-WVDHostPool.ps1</a> and <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/scripts/Update-WVDHostPoolV2.ps1" target="_blank">Update-WVDHostPoolV2.ps1</a> are currently not used in the automation, but they can be used to update existing host pools with a new image.

#### QS-WVD/static
This folder contains the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/QS-WVD/static/appliedParameters.template.psd1" target="_blank">appliedParameters.template.psd1</a>, which is the template used by the initial ARM deployment to generate the *appliedParameters.psd1* file explained <a href="customize" target="_blank">here</a>.

#### QS-WVD/static/templates/pipelineinput
This folder contains all the templates for ARM deployment parameter files. These templates are used by the DevOps pipeline as explained <a href="devops" target="_blank">here</a> to generate the parameter files for the deployment of WVD resources in the pipeline. The name of the template file indicates what resource it's used for - I will not go deeper into these here.

### <b>SharedDeploymentFunctions</b>
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions/Add-CustomParameters.ps1" target="_blank">Add-CustomParameters.ps1</a>: This script is called by the pipeline to add additional parameters to a resource deployment, in certain cases; For example, this function is used to add an extra parameter when using Azure AD DS as identity solution to correctly configure the storage account settings.
* <b><a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions/Invoke-GeneralDeployment.ps1" target="_blank">Invoke-GeneralDeployment.ps1</a></b>: This all-important script is called for any resource deployment in the pipeline. This script finds the correct ARM template to deploy that resource, passes the correct parameters as arguments, and starts the ARM deployment.

#### SharedDeploymentFunctions/Imaging
The scripts in this folder can be used to allow for custom VM images in the solution. These are currently not used.

#### SharedDeploymentFunctions/Storage
This folder contains three scripts that are used in the deployment of the Assets storage account (where we store the Custom Script Extension (CSE) files):
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions/Storage/Compress-WVDCSEContent.ps1" target="_blank">Compress-WVDCSEContent.ps1</a>: This script packages all the CSE files into zip folder to allow for upload to the assets storage account blob.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions/Storage/Export-WVDCSEContentToBlob.ps1" target="_blank">Export-WVDCSEContentToBlob.ps1</a>: This script uploads the created zip folders to a blog storage in the assets storage account.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/SharedDeploymentFunctions/Storage/Import-WVDSoftware.ps1" target="_blank">Import-WVDSoftware.ps1</a>: This script downloads the zip folders onto the VM onto which the CSE is to be installed.

### <b>Uploads</b>
This folder contains the CSEs for the WVD VMs, and it's named uploads as it will in its entirety be uploaded to the assets storage account. It also contains the ZIP folder *Configuration.zip* which contains the configuration files for the DSC extension to be installed on the WVD VMs. 

#### Uploads/WVDScripts
Every CSE is run through the *cse_run.ps1* file in each subfolder - These scripts are called by the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/scriptExtensionMasterInstaller.ps1" target="_blank">scriptExtensionMasterInstaller.ps1</a> script. This script unzips the downloaded CSE folders and proceeds to look for *cse_run.ps1* files to execute. The other file you will find in this folder is the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/downloads.parameters.json" target="_blank">downloads.parameters.json</a> file. This file contains parameters for certain files that need to be downloaded from the internet to install some of the applications configured in the CSEs. For example, it specifies where to find the FSLogix executable, so that it can be downloaded onto the VM. Let's now dive into each specific CSE in a little more depth:

* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles" target="_blank">/001-AzFiles</a>: This first custom script extension is used when using a Native AD identity approach (not when using Azure AD DS) to enable Azure Files as explained <a href="https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable" target="_blank">here</a>. It does so using AzureFilesHybrid, which is used to domain join the storage account. The file structure in this folder is as follows:
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/cse_run.ps1" target="_blank">/cse_run.ps1</a>: Main CSE script, which is then used to call the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/setup.ps1" target="_blank">setup.ps1</a> file in the same folder to domain join the storage account.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/setup.ps1" target="_blank">/setup.ps1</a>: Carries out the domain join of the storage account using the AzFilesHybrid module. This script is run in the context of the domain administrator using the PSExec module.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/AzFilesHybrid.psd1" target="_blank">/AzFilesHybrid.psd1</a>, <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/AzFilesHybrid.psm1" target="_blank">/AzFilesHybrid.psm1</a>, and <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/CopyToPSPath.ps1" target="_blank">/CopyToPSPath.ps1</a> are all files needed to install or use the AzFilesHybrid module in the *setup.ps1* script.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/PSExec.exe" target="_blank">/PSExec.exe</a>, <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/PSExec64.exe" target="_blank">/PSExec64.exe</a>, <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/Eula.txt" target="_blank">/Eula.txt</a>, <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/Pstools.chm" target="_blank">/Pstools.chm</a>, and <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/001-AzFiles/psversion.txt" target="_blank">/psversion.txt</a> are all files needed for the PSExec module that is used to run the domain join of the storage account in the admin context (rather than the machine context in which CSEs are run by default). 
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/002-FSLogix" target="_blank">/002-FSLogix</a>
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/002-FSLogix/cse_run.ps1" target="_blank">/cse_run.ps1</a>: Main CSE script that is called to install the FSLogix CSE. From this script, the remaining scripts in this folder are called to configure FSLogix.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/002-FSLogix/Install-FSLogix.ps1" target="_blank">/Install-FSLogix.ps1</a>: This script carries out the initial install of FSLogix using the downloaded executable file.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/002-FSLogix/Set-FSLogix.ps1" target="_blank">/Set-FSLogix.ps1</a>: Configures FSLogix, setting the appropriate registry keys to the right values.
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/002-FSLogix/Set-NTFSPermissions.ps1" target="_blank">/Set-NTFSPermissions.ps1</a>: This script is used to configure the permissions on the file share, and to mount the profile drive on the VM using New-PSDrive.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/003-NotepadPP" target="_blank">/003-NotepadPP</a>
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/003-NotepadPP/cse_run.ps1" target="_blank">/cse_run.ps1</a>: Main CSE script that is called to install NotepadPlusPlus using the downloaded executable file.
* <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/004-Teams" target="_blank">/004-Teams</a>
  * <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Uploads/WVDScripts/004-Teams/cse_run.ps1" target="_blank">/cse_run.ps1</a>: Main CSE script that is called to install Microsoft Teams using the downloaded executable file. This script will also set the Teams registry key required for it to work in a virtualized environment.

### <b><a href="https://github.com/samvdjagt/wvdquickstart/tree/master/deploy.json" target="_blank">deploy.json</a></b>
This is the ARM template used for the initial deployment, which is explained in a high-level <a href="concepts" target="_blank">here</a> and in a detailed breakdown <a href="armdeployment" target="_blank">here</a>.
 
