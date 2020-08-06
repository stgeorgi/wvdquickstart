#Initializing variables from automation account
$SubscriptionId = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$AutomationAccountName = Get-AutomationVariable -Name 'AccountName'
$AppName = Get-AutomationVariable -Name 'AppName'

# Download files required for this script from github ARMRunbookScripts/static folder
$FileNames = "msft-wvd-saas-api.zip,msft-wvd-saas-web.zip,AzureModules.zip"
$SplitFilenames = $FileNames.split(",")
foreach($Filename in $SplitFilenames){
Invoke-WebRequest -Uri "$fileURI/ARMRunbookScripts/static/$Filename" -OutFile "C:\$Filename"
}

# Install required Az modules and AzureAD
Expand-Archive "C:\AzureModules.zip" -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

Import-Module Az.Accounts -Global
Import-Module Az.Resources -Global
Import-Module Az.Websites -Global
Import-Module Az.Automation -Global
Import-Module AzureAD -Global

Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
Get-ExecutionPolicy -List
#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
$AzCredentialsAsset = 'AzureCredentials'

#Authenticate Azure
#Get the credential with the above name from the Automation Asset store
$AzCredentials = Get-AutomationPSCredential -Name $AzCredentialsAsset
$AzCredentials.password.MakeReadOnly()
$username = $AzCredentials.username
Connect-AzAccount -Environment 'AzureCloud' -Credential $AzCredentials
Connect-AzureAD -AzureEnvironmentName 'AzureCloud' -Credential $AzCredentials
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get the context
$context = Get-AzContext
if ($context -eq $null)
{
	Write-Error "Please authenticate to Azure & Azure AD using Login-AzAccount and Connect-AzureAD cmdlets and then run this script"
	exit
}

# Get the Role Assignment of the authenticated user
$RoleAssignment = Get-AzRoleAssignment -SignInName $context.Account

# Validate whether the authenticated user having the Owner or Contributor role
if ($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{
	#$requiredAccessName=$ResourceURL.Split("/")[3]
	$redirectURL = "https://" + "$AppName" + ".azurewebsites.net" + "/"
	
	# Check whether the AD Application exist/ not
	$azAdApplication = Get-AzADApplication -DisplayName $AppName -ErrorAction SilentlyContinue
	if ($azAdApplication -ne $null)
	{
		$appId = $azAdApplication.ApplicationId
		Write-Output "An AAD Application already exists with AppName $AppName(Application Id: $appId). Will attempt to handle deployment with this existing application." -Verbose
	}
	else {
		try
		{
			Write-Output "Creating new application..."
			# Create a new AD Application with provided AppName
			$azAdApplication = New-AzureADApplication -DisplayName $AppName -PublicClient $false -AvailableToOtherTenants $false -ReplyUrls $redirectURL
		}
		catch
		{
			Write-Error "You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
			exit
		}
	}
	$azAdApplication = Get-AzADApplication -DisplayName $AppName -ErrorAction SilentlyContinue

	# Create a Client Secret
	$StartDate = Get-Date
	$EndDate = $StartDate.AddYears(280)
	$Guid = New-Guid
	$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
	$PasswordCredential.StartDate = $StartDate
	$PasswordCredential.EndDate = $EndDate
	$PasswordCredential.KeyId = $Guid
	$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid)))) + "="
	$ClientSecret = $PasswordCredential.Value

	Write-Output "Creating a new Application in AAD" -Verbose
	
	# Create an app credential to the Application
	$secureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
	New-AzADAppCredential -ObjectId $azAdApplication.ObjectId -Password $secureClientSecret -StartDate $StartDate -EndDate $EndDate

	# Get the applicationId
	$applicationId = $azAdApplication.ApplicationId
	Write-Output "Azure AAD Application creation completed successfully with AppName $AppName (Application Id is: $applicationId)" -Verbose

	# Create new Service Principal
	Write-Output "Creating a new Service Principal" -Verbose
	$ServicePrincipal = Get-AzADServicePrincipal -ApplicationId $applicationId -ErrorAction SilentlyContinue
	if ($ServicePrincipal -ne $null)
	{
		Write-Output "A service principal already exists for this AAD application. Will attempt to handle deployment with this existing service principal." -Verbose
	}
	else {
		try
		{
			$ServicePrincipal = New-AzADServicePrincipal -ApplicationId $applicationId
		}
		catch
		{
			Write-Error "You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
			exit
		}
	}
	
	# Get the Service Principal
	Get-AzADServicePrincipal -ApplicationId $applicationId
	Write-Output "Service Principal creation completed successfully for AppName $AppName (Application Id is: $applicationId)" -Verbose

	$ownerId = (Get-AzADUser -UserPrincipalName $username).Id
	Add-AzureADApplicationOwner -ObjectId $azAdApplication.ObjectId -RefObjectId $ownerId
	Write-Output "Azure admin successfully assigned owner role on the service principal" -Verbose

	#Collecting AzureService Management Api permission and set to client app registration
	$AzureServMgmtApi = Get-AzADServicePrincipal -ApplicationId "797f4846-ba00-4fd7-ba43-dac1f8f63013"
	$AzureAdServMgmtApi = Get-AzureADServicePrincipal -ObjectId $AzureServMgmtApi.Id
	$AzureServMgmtApiResouceAcessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureServMgmtApiResouceAcessObject.ResourceAppId = $AzureAdServMgmtApi.AppId
	foreach ($SerVMgmtAPipermission in $AzureAdServMgmtApi.Oauth2Permissions) {
		$AzureServMgmtApiResouceAcessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $SerVMgmtAPipermission.Id,"Scope"
	}

	# Set Microsoft Graph API permission to Client App Registration
	$MsftGraphApi = Get-AzADServicePrincipal -ApplicationId "00000003-0000-0000-c000-000000000000"
	$AzureGraphApiPrincipal = Get-AzureADServicePrincipal -ObjectId $MsftGraphApi.Id
	$AzureGraphApiAccessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureGraphApiAccessObject.ResourceAppId = $AzureGraphApiPrincipal.AppId
	$permission = $AzureGraphApiPrincipal.Oauth2Permissions | Where-Object { $_.Value -eq "User.Read" }
	$AzureGraphApiAccessObject.ResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
	$permission2 = $AzureGraphApiPrincipal.Oauth2Permissions | Where-Object { $_.Value -eq "User.ReadWrite" }
	$AzureGraphApiAccessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission2.Id,"Scope"
	$permission3 = $AzureGraphApiPrincipal.Oauth2Permissions | Where-Object { $_.Value -eq "Group.ReadWrite.all" }
	$AzureGraphApiAccessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission3.Id,"Scope"
	$permission4 = $AzureGraphApiPrincipal.AppRoles | Where-Object { $_.Value -eq "Application.ReadWrite.OwnedBy" }
	$AzureGraphApiAccessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission4.Id,"Role"

	# Add the WVD API,Log Analytics API and Microsoft Graph API permissions to the ADApplication
	Set-AzureADApplication -ObjectId $azAdApplication.ObjectId -RequiredResourceAccess $AzureServMgmtApiResouceAcessObject,$AzureGraphApiAccessObject -ErrorAction Stop
    #Set-AzureADApplication -ObjectId $azAdApplication.ObjectId -Oauth2Permissions $AzureAdOauth2Object -Oauth2RequirePostResponse $false -Oauth2AllowImplicitFlow $true
	
	# Create credential for the service principal and store in the automation account
	$global:servicePrincipalCredentials = New-Object System.Management.Automation.PSCredential ($applicationId, $secureClientSecret)
	New-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name "ServicePrincipalCred" -Value $servicePrincipalCredentials -ResourceGroupName $ResourceGroupName

	# Create new automation variables with the newly created service principal details in them for use in the devops setup script
	New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name "PrincipalId" -Encrypted $False -Value $applicationId -ResourceGroupName $ResourceGroupName
	New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name "Secret" -Encrypted $False -Value $secureClientSecret -ResourceGroupName $ResourceGroupName
	New-AzAutomationVariable -AutomationAccountName $AutomationAccountName -Name "ObjectId" -Encrypted $False -Value $azAdApplication.ObjectId -ResourceGroupName $ResourceGroupName

	# Assign service principal contributor and user acess administrator roles on subscription level
	New-AzRoleAssignment -RoleDefinitionName "Contributor" -ApplicationId $applicationId
	New-AzRoleAssignment -RoleDefinitionName "User Access Administrator" -ApplicationId $applicationId
}
else
{
	Write-Error "Authenticated user should have the Owner/Contributor permissions"
}
