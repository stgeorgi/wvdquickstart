---
title: How-to
layout: template
filename: howto
---

## <b>How To Deploy With The WVD QuickStart</b>

<iframe width="784" height="441" src="https://www.youtube.com/embed/Tz3KgruovYc" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
The video above shows you a full end-to-end deployment with the WVD QuickStart, including the configuration of the prerequisites listed below.

### <b>Prerequisites</b>
In order to successfully deploy a WVD environment with the QuickStart, a couple of prerequisites need to be satisfied beforehand. All of these prerequisites are listed below, together with links to documentation that can help you with setting them up.
* An active <a href="https://azure.microsoft.com/en-us/" target="_blank">Azure subscription</a>
* Sufficient <a href="https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-portal" target="_blank">administrator privileges</a> on your subscription: you will need the *owner* role
* Either one of the following: 
   * A 
<a href="https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview" target="_blank">Windows Server Active Directory</a> (AD) in sync with <a href="https://azure.microsoft.com/en-us/services/active-directory/" target="_blank">Azure Active Directory</a> (AAD), configured with <a href="https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-express" target="_blank">AD Connect</a>
   * OR: Configured <a href="https://azure.microsoft.com/en-us/services/active-directory-ds/" target="_blank">Azure Active Directory Domain Services (Azure AD DS)</a> setup
* Domain join service account (Must be without MFA) with sufficient priviliges to join machines to the domain. When using Azure AD DS, this user must be a member of the *AAD DC Administrators* Azure AD Group
* Existing virtual network (VNET)
    * With an available subnet
    * With the DNS setting to *custom*
    * Domain join service account needs to have administrator privileges on the domain controller in this VNET
* Firewall configuration: ensure all the <a href="https://docs.microsoft.com/en-us/azure/virtual-desktop/safe-url-list" target="_blank">required ports</a> are accessible to the WVD resource provider

Additionally, the QuickStart will set up <a href="https://dev.azure.com" target="_blank">Azure DevOps</a> for you. This is not a prerequisite that requires action from you as the user, but it's good to be aware of the fact that this particular service will be leveraged in this automation. Once you have all of these prerequisites satisfied, <a href="https://youtu.be/Tz3KgruovYc?t=360" target="_blank">this video</a> will show you a walkthrough of the QuickStart deployment outlined below.

### <b>Get started: ARM Deployment - Azure DevOps Setup</b>
Once you've satisfied all the prerequisites, you are ready to deploy using the QuickStart! As explained in the <a href="concepts">Concepts</a> section, the deployment consists of two main components: an Azure Resource Manager (ARM) deployment and an Azure DevOps (ADO) pipeline. The first of the two will deploy a number of resources supporting the deployment automation, including the creation of a DevOps project and automation pipeline. By clicking the "Deploy to Azure" button, you will be taken to the Azure Portal for a custom deployment. There, you can fill out the required user input and click *purchase*. 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2Fsamvdjagt%2Fwvdquickstart%2Fmaster%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a><br>

The above button will take you to the Azure Portal, where your screen should look like the image below. To understand what input is expected for all the listed parameters, the 'i' balloons to the left of every parameter will give you guidance.

![ARM Template](images/ARMInput.PNG?raw=true)

### <b>WVD Deployment: DevOps Pipeline</b>
Once the ARM deployment completes, your WVD environment will automatically be deployed by an Azure DevOps pipeline. While no further action from you is required, you can follow along with this deployment, in <a href="https://dev.azure.com" target="_blank">Azure DevOps</a>, where you will find the WVD QuickStart project. Navigate to the "pipelines" section - Here you'll find a running pipeline that deploys a WVD environment (VMs, host pool, desktop app group, FSLogix configuration) for you. Upon completion of this pipeline, which will take about 25 minutes, your WVD environment is ready for use! You can also follow along with the deployment in the Azure Portal. Once the pipeline finished, you will receive an email from Azure DevOps (if you have supplied a notification email in the ARM deployment) informing you of its completion. Once you receive this email, your WVD environment is ready for use!

Withing Azure Devops, after clicking on your project and its pipeline, you will see something like this:
![DevOps Pipeline](images/devopsPipeline.PNG?raw=true)

If you click on the pipeline's jobs, you will be able to follow along with the deployment. This will give you a sense of the progress made so far in the deployment and it will also be the place where you'll receive your error messaging, should the deployment fail.
![DevOps Pipeline Progress](images/devopsPipelineProgress.PNG?raw=true)

### <b>Using Your New WVD Environment</b>
The QuickStart creates a test user for you to try out the environment. Navigate to the <a href="https://rdweb.wvd.microsoft.com/arm/webclient/index.html" target="_blank">WVD web client</a> or install the WVD client locally (from <a href="https://aka.ms/wvd/clients" target="_blank">here</a>) and login with the following test user credentials:

Username: WVDTestUser001@{your-domain}.com <br>
Password: Taken from DevOps organization in the following way: If organization is called <b>"WVDQuickStartOrg120011Z"</b>, your password will be "<b>Org120011Z!</b>" (case sensitive, and don't forget the exclamation point at the end) 
(Disclaimer: You should change this password at your earliest convenience.)

You should see a "WVD Workspace" appear, to which you can login to experience the best of Windows Virtual Desktop. Within this virtualized environment, your user will find Microsoft Office 365 amongst other built-in Microsoft applications. Additionally, since the QuickStart configures FSLogix profile management for you, a user profile will be created. This will be stored in the profiles storage account, in the *wvdprofiles* file share.
