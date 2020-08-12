---
title: How-to
layout: template
filename: howto
---

## <b>How To Use The WVD QuickStart With an Empty Subscription</b>
On this page, the process of using the WVD QuickStart with an empty Azure subscription is laid out from start to finish. The QuickStart will configure Windows Virtual Desktop as well as Azure Active Directory Domain Services for you. All that is required is an empty Azure subscription as listed below, and after clicking one button, WVD will be ready for use within 2 hours. The video below shows a walkthrough of the entire deployment process.

<iframe width="100%" height="441" src="https://www.youtube.com/embed/rhw6KoM0cJ8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### <b>Prerequisites</b>
In order to successfully deploy a WVD environment with the QuickStart, the only prerequisites you will need are the following two:
* An active <a href="https://azure.microsoft.com/en-us/" target="_blank">Azure subscription</a>
* Sufficient <a href="https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-portal" target="_blank">administrator privileges</a> on your subscription: you will need the *owner* role

Additionally, the QuickStart will set up <a href="https://dev.azure.com" target="_blank">Azure DevOps</a> for you. This is not a prerequisite that requires action from you as the user, but it's good to be aware of the fact that this particular service will be leveraged in this automation. Once you have all of these prerequisites satisfied, <a href="https://youtu.be/Tz3KgruovYc?t=360" target="_blank">this video</a> will show you a walkthrough of the QuickStart deployment outlined below.

### <b>Get started: ARM Deployment - Azure AD DS & Azure DevOps Setup</b>
Once you've satisfied all the prerequisites, you are ready to deploy using the QuickStart! As explained in the <a href="concepts">Concepts</a> section, the deployment consists of two main components: an Azure Resource Manager (ARM) deployment and an Azure DevOps (ADO) pipeline. The first of the two will deploy a number of resources supporting the deployment automation, including the creation of an Azure AD DS managed domain, to which the WVD virtual machines will be 'domain-joined', as well as an Azure DevOps project and automation pipeline. By clicking the "Deploy to Azure" button, you will be taken to the Azure Portal for a custom deployment. There, you can fill out the required user input and click *purchase*. It is recommended that you create a new resource group for the QuickStart to deploy in, as this will make it easier to delete its resources.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2Fstgeorgi%2Fwvdquickstart%2Fmaster%2FNewSubAADDSSetup%2Fdeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a><br>

The above button will take you to the Azure Portal, where your screen should look like the image below. To understand what input is expected for all the listed parameters, the 'i' balloons to the left of every parameter will give you guidance.

![ARM Template](images/ARMInputAADDS.PNG?raw=true)

This deployment will deploy the resources outlined in the <a href="concepts">How it works</a> section. The credentials you enter in the Portal will be securely stored as secrets in both an Azure keyvault and an Azure DevOps secret.

### <b>WVD Deployment: DevOps Pipeline</b>
Once the ARM deployment completes, your WVD environment will automatically be deployed by an Azure DevOps pipeline. While no further action from you is required, you can follow along with this deployment, in <a href="https://dev.azure.com" target="_blank">Azure DevOps</a>, where you will find the WVD QuickStart project. Navigate to the "pipelines" section - Here you'll find a running pipeline that deploys a WVD environment (VMs, host pool, desktop app group, FSLogix configuration) for you. Upon completion of this pipeline, which will take about 20 minutes, your WVD environment is ready for use! You can also follow along with the deployment in the Azure Portal. Once the pipeline finished, you will receive an email from Azure DevOps (if you have supplied a notification email in the ARM deployment) informing you of its completion. Once you receive this email, your WVD environment is ready for use!

Withing Azure Devops, after clicking on your project and its pipeline, you will see something like this:
![DevOps Pipeline](images/devopsPipeline.PNG?raw=true)

If you click on the pipeline's jobs, you will be able to follow along with the deployment. This will give you a sense of the progress made so far in the deployment and it will also be the place where you'll receive your error messaging, should the deployment fail.
![DevOps Pipeline Progress](images/devopsPipelineProgress.PNG?raw=true)

### <b>Using Your New WVD Environment</b>
The QuickStart creates a test user for you to try out the environment. Navigate to the <a href="https://rdweb.wvd.microsoft.com/arm/webclient/index.html" target="_blank">WVD web client</a> or install the WVD client locally (from <a href="https://aka.ms/wvd/clients" target="_blank">here</a>) and login with the following test user credentials:

Username: WVDTestUser001@{your-domain}.com <br>
Password: Taken from DevOps organization in the following way: If organization is called <b>"WVDQuickStartOrg120011Z"</b>, your password will be "<b>Org120011Z!</b>" (case sensitive, and don't forget the exclamation point at the end) 
(Disclaimer: You should change this password at your earliest convenience.)

You should see a "WVD Workspace" appear, to which you can login to experience the best of Windows Virtual Desktop. Within this virtualized environment, your user will find Microsoft Office 365 and Microsoft Teams amongst other built-in Microsoft applications. Additionally, since the QuickStart configures FSLogix profile management for you, a user profile will be created. This will be stored in the profiles storage account, in the *wvdprofiles* file share.

### <b>Using the AADDS administrator account</b>
In the automation, the QuickStart creates an administrator account (member of the AAD DC Administrators group) that can be used to manage the deployed domain. This is also the account used to domain join virtual machines, should you want to join additional VMs in the future. The credentials for this created account are the following, by default:

Username: domainJoiner@{your-domain}.com <br>
Password: The same as your Azure admin account password (that you entered in the initial ARM deployment)

### <b>Deleting the WVD environment and the QuickStart resources </b>
In case you want to delete your WVD environment and all the QuickStart resources from your Azure subscription, there's a couple of steps to take. First, you can delete the resource group that the QuickStart was deployed in. This will delete your WVD environment and most of the QuickStart resources. Then, in the Azure portal, 
* Go to Azure Active Directory --> App registrations and remove the "WVDServicePrincipal"
* Go to Azure Active Directory --> Groups and remove the "WVDTestUsers" group
* Go to Azure Active Directory --> Users and remove the "WVDTestUser001" user profile
* Navigate to <a href="https://dev.azure.com" target="_blank">Azure DevOps</a> and delete the WVD QuickStart organization by going to the organization's settings and scrolling to the bottom of the page.
