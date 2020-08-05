# WVD QuickStart

Welcome to the WVD QuickStart GitHub repository! The WVD QuickStart is a solution intended to simplify and automate WVD deployments, empowering IT professionals to get started with WVD in a matter of clicks. New to WVD? Check out https://aka.ms/wvddocs for more information. 

By clicking the "Deploy to Azure" button, you will be taken to the Azure Portal for a custom deployment. There, you can fill out the required user input and click "deploy". This will set up some resources needed for the QuickStart, including an Azure DevOps project.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2Fsamvdjagt%2Fwvdquickstart%2Fmaster%2Fdeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a><br>


Once the deployment completes, please navigate to https://dev.azure.com, where you will find the WVD QuickStart project. Navigate to the "pipelines" section - Here you'll find a running pipeline that deploys a WVD environment (VMs, host pool, desktop app group, FSLogix configuration) for you. Upon completion of this pipeline, which will take about 15 minutes, your WVD environment is ready for use!

The QuickStart creates a test user for you to try out the environment. Navigate to https://rdweb.wvd.microsoft.com/arm/webclient/index.html and login with the following test user credentials:

Username: WVDTestUser001@{your-domain}.com <br>
Password: Taken from DevOps organization in the following way: If organization is called "WVDQuickStartOrg120011Z", your password will be "Org120011Z!" (case sensitive, and don't forget the exclamation point at the end) 
(Disclaimer: You should change this password at your earliest convenience.)



