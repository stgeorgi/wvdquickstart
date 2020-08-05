---
title: Troubleshoot
layout: template
filename: troubleshoot
---

## <b>WVD QuickStart Troubleshooting</b>
In case you run into any issues while using the WVD QuickStart, this page might prove helpful to you. This page will cover certain common errors, as well as ways to solve them. Additionally, this page lists some known limitations of the solution.

### <b>Known Limitations</b>
* In the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM/UserCreation/scripts/createUsers.ps1" target="_blank">userCreation</a> custom script extension, there's a small chance it will fail when trying to sync the newly created user to Azure AD, if a sync cycle is already running. Additionally, it's possible that the ADSync module is not present on your domain controller. This means it could take up to 30 minutes for the test user to get synced to Azure Active Directory. If this is the case, the deployment will work, but it can take up to 30 minutes longer than if the ADSync module was present on your domain controller.
* The WVD QuickStart cannot configure your native AD environment for you. You will have to have a virtual network and domain controller setup and synced to Azure AD (with AD Connect) as a prerequisite before deploying with the QuickStart. The video on the <a href="howto">Getting Started page</a> shows you how you can do that. In the case of using Azure AD DS, you will also have to have your environment setup as this is not automated in the QuickStart either.
  * The QuickStart assumes your domain controller to be in the same resource group as the virtual network, and if this is not the case, the deployment will fail. You can overwrite this in the ARM template by manually providing the name of the resource group your domain controller is in.
* Currently, the QuickStart will only work if you are the subscription owner. In theory, it could work if you have both *contributor* and *user access administrator* roles on the subscription, but this is not currently a tested scenario. Moreover, it is currently not supported to run the QuickStart with a Service Principal. Instead, you will be asked for your full Azure admin credentials. These credentials will never be stored in any logs as plain text. Rather, they will be stored as secrets in an Azure Keyvault and a DevOps variable secret.
* Currently, the DevOps organization will by default be created in the *Central US* region. DevOps available regions are different from the Azure Portal regions and the user input on this is therefore not used to select a DevOps region. This has no effect on where your WVD environment will be deployed, only on where the DevOps repository is hosted. This region can be manually modified in the main ARM deployment template (<a href="https://github.com/samvdjagt/wvdquickstart/tree/master/deploy.json" target="_blank">deploy.json</a>)
* After crossing a certain compute threshold, using Azure DevOps will start incurring costs for you. However, the QuickStart remains well within those limits and will likely not incur any costs at all. For more information on Azure DevOps billing, see the documentation <a href="https://docs.microsoft.com/en-us/azure/devops/organizations/billing/overview?view=azure-devops" target="_blank">here</a>.

### <b>Invalid Configuration</b>
A likely cause of a WVD QuickStart failure is if one or more of the <a href="howto">prerequisites</a> is either not present or incorrectly configured. While some of these are validated in the automation, these prerequisites are an absolute requirement in the configuration specified <a href="howto">here</a>.

### <b>DevOps Pipeline Error</b>
Sometimes, the DevOps pipeline will give you an error that has no clear cause. Often times, these are transient errors that can be fixed by simply running the pipeline again - By clicking "Run New" at the top of your screen. 

### <b>Runbook failed</b>
If you get an error that looks like the image below, it means that the deployment was unable to authenticate to your Azure account, or that there was some other error with your current Azure environment. Note: While this section covers the checkCredentialsRunbook specifically, the process is the same for any runbook error in your deployment.
![Job failed](images/jobFail.PNG?raw=true)
<br>To troubleshoot this issue, go to the resource group to which you are currently deploying, and click on the checkCredentialsRunbook as shown below:
![runbook](images/runbook.PNG?raw=true)
Within that runbook, you will see that the job Failed, as shown below:
![Job failed](images/runbookFailed.PNG?raw=true)
<br>If you click on the job, and navigate to the *Errors* tab, you'll see the error messaging from the script. This will help you understand the cause of the error. In the example below, we can see that the wrong credentials were entered - Which indicates a spelling mistake in either the Azure Admin UPN or password. 
![job error](images/jobError.PNG?raw=true)
<br>To fix this, simply click "Redeploy" in the main deployment, and make sure the credentials you entered are correct before clicking "Purchase" again.

### <b>Native AD: Creating Users</b>
In case you are running a Native AD deployment, and the 'UserCreation' fails, there are a number of possible causes:

* <b>Incorrect domain join credentials entered</b>: This is the most common reason for this step to fail. If this is the reason, the error message would look like the following:
![userCreation error](images/credError.PNG?raw=true)
In that case, go back to the deployment page, click "redeploy", re-enter your password and simply click "purchase" again to retry the deployment.
* Incorrect configuration of the domain controller VM: Please ensure that the VM is running and healthy, and that the RDAgent is installed, running and responding to commands on your domain controller VM. Otherwise, re-install the agent.
* There's another Custom Script Extension already installed on your domain controller VM: In this case, the userCreation will not be able to run. If possible, uninstall the existing custom script extension. Otherwise, create the user manually as explained below.
* A failure when running the <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/Modules/ARM/UserCreation/scripts/createUsers.ps1" target="_blank">createUsers.ps1</a> script: You could try and edit it to troubleshoot, but it might be easier to log on to your domain controller and create the user manually. Be sure to then assign that user to a Security Group with the same name as the variable 'targetGroup' in the main <a href="https://github.com/samvdjagt/wvdquickstart/tree/master/deploy.json" target="_blank">deploy.json</a> and to sync this change to Azure with AD Connect. Your deployment will only work if the user is synced to Azure. If you go down this manual route, you do want to get rid of the 'UserCreation' deployment in the main deploy.json to avoid your deployment failing again.

### <b>Pipeline Error in Deploying a Resource</b>
The first step in troubleshooting any pipeline failures is to check the parameter files for correctness. It's possible that in the parameter file generation one of the files was configured incorrectly, resulting in a syntax error or, for example, a missing parameter value. To validate these parameter files, navigate to your pipeline and click on the build artifact containing the parameter files as indicated in the image below.

![DevOps Pipeline Artifact](images/devopsArtifact.PNG?raw=true)

Within this *Artifact* you will find a folder called 'Parameters' - Click on it, and you'll see all the generated parameter files. You can then download the one with associated resource that failed the pipeline to check it for correctness. If the error was indeed due to a parameter error, please change this parameter in either the *appliedParameters.psd1* and/or *variables.yml* files as explained in the <a href="customize" target="_blank">Customize</a> section. Then, you can start a new run of the pipeline, which will regenerate the parameter files (don't click "rerun failed jobs", as this will use the same faulty parameter files). 

As a last resort, if the above does not fix your problem, you can try hard-coding some parameters in the parameter template files located in the *QS-WVD/static/templates/pipelineinput* folder in your DevOps repository. However, this is not a recommended course of action.

#### Assets Storage Account Post-Deployment Failed: Download Failed
In deploying the assets storage account, one of the tasks is to download the Microsoft Teams MSI package. There's a slight possibility that this particular task gives you the following error in the DevOps pipeline

*Download FAILED: Exception calling "DownloadFile" with "2" <br>
     | argument(s): "The SSL connection could not be established, see <br>
     | inner exception. Authentication failed, see inner exception."*

If this happens, you can simply click "Rerun failed jobs" at the top of the screen - This should fix this issue, as it's not a user error.
