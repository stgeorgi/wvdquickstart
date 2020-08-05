---
title: Concepts
layout: template
filename: concepts
---

## <b>Conceptual breakdown of the WVD QuickStart</b>
To understand how the WVD QuickStart works, this page will walk you through a conceptual overview. In addition to the overview on this page, the links below provide a more in-depth walkthrough of certain components of the solution, which can be very helpful in case you want to understand the code behind the solution or when you want to more advanced customizations.

* For an in-depth breakdown of the ARM template used to configure DevOps, which is the template used when you click the blue "Deploy to Azure" button, please see <b><a href="armdeployment">Azure Resource Manager deployment: DevOps setup</a></b>
* For an in-depth analysis of the DevOps automation used to deploy the WVD environment, please visit <b><a href="devops">DevOps Automation</a></b>
* To understand this GitHub repository, its structure and all its individual files, the <b><a href="repo">Respository breakdown by file</a></b> gives an in-depth walkthrough of the entire repository with explanations on individual files' purpose and role.

### <b>Conceptual Deployment Overview</b>
As stated in the overview, the WVD QuickStart takes much of the WVD deployment complexity away, simplifying and automating the process, making the platform more accessible to non-expert users. As a WVD-centric end-to-end solution, the quickstart addressess reported pain points, challenges and feature gaps, empowering IT professionals to get started with WVD in a matter of clicks. This page will help you answer how exactly the QuickStart achieves that. The diagram below shows a high-level conceptual overview of the deployment with the WVD QuickStart:
![Deployment overview](images/overview.PNG?raw=true)
In short, the QuickStart requires you to have some prerequisites - From which it will, in a fully automated way using Azure Devops, deploy a functional WVD environment with virtual machines running Windows 10 Enterprise Multi-Session, build 2004, with Office 365 and Microsoft Teams installed. Additionally, the virtual machines will be configured with <a href="https://docs.microsoft.com/en-us/fslogix/overview">FSLogix</a> for user profile management. Upon completion, a test user can login to the environment and experience the best of what WVD has to offer.

### <b>Resources</b>
In short, the deployment with the WVD QuickStart consists of two main parts:

* An Azure Resource Manager (ARM) deployment that deploys a number of supporting resource and creates an Azure DevOps (ADO) automation pipeline
* An Azure DevOps pipeline, created by the above deployment, that will automatically deploy a WVD environment for you

After clicking the "Deploy to Azure" button, the first of the two can be kicked off after providing some limited user input. Following that deployment, the DevOps pipeline will automatically start and deploy a WVD environment for you.The diagram below gives a good overview of all components of the QuickStart, as well as all the resources that are deployed in the process.

![Deployment overview](images/newDiagram.PNG?raw=true)

As can be seen in the image, the DevOps automation will deploy a host pool, a desktop application group, a workspace and virtual machines, that upon completion of the pipeline will be ready for use. By default, the virtual machines will utilize a gallery OS image of Windows 10 Enterprise Multi-Session, build 2004, with Office 365 and Microsoft Teams installed and FSLogix configured. This can be customized, if desired, to be a different gallery image or a custom image using the Shared Image Gallery. 
