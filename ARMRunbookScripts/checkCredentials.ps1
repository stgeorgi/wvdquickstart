#Initializing variables from automation account
$SubscriptionId = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$existingVnetName = Get-AutomationVariable -Name 'existingVnetName'
$existingSubnetName = Get-AutomationVariable -Name 'existingSubnetName'

# Download files required for this script from github ARMRunbookScripts/static folder
$FileNames = "msft-wvd-saas-api.zip,msft-wvd-saas-web.zip,AzureModules.zip"
$SplitFilenames = $FileNames.split(",")
foreach($Filename in $SplitFilenames){
Invoke-WebRequest -Uri "$fileURI/ARMRunbookScripts/static/$Filename" -OutFile "C:\$Filename"
}

#New-Item -Path "C:\msft-wvd-saas-offering" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\AzureModules.zip" -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

# Install required Az modules and AzureAD
Import-Module Az.Accounts -Global
Import-Module Az.Resources -Global
Import-Module Az.Websites -Global
Import-Module Az.Automation -Global
Import-Module Az.Managedserviceidentity -Global
Import-Module Az.Keyvault -Global
Import-Module Az.Network -Global
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
Connect-AzAccount -Environment 'AzureCloud' -Credential $AzCredentials
Select-AzSubscription -SubscriptionId $SubscriptionId

$context = Get-AzContext
if ($context -eq $null)
{
	Write-Error "Please authenticate to Azure & Azure AD using Login-AzAccount and Connect-AzureAD cmdlets and then run this script"
	throw
}
$AADUsername = $context.Account.Id

#region connect to Azure and check if Owner
Try {
	Write-Output "Try to connect AzureAD."
	Connect-AzureAD -Credential $AzCredentials
	
	Write-Output "Connected to AzureAD."
	
	# get user object 
	$userInAzureAD = Get-AzureADUser -Filter "UserPrincipalName eq `'$AADUsername`'"

	$isOwner = Get-AzRoleAssignment -ObjectID $userInAzureAD.ObjectId | Where-Object { $_.RoleDefinitionName -eq "Owner"}

	if ($isOwner.RoleDefinitionName -eq "Owner") {
		Write-Output $($AADUsername + " has Owner role assigned")        
	} 
	else {
		Write-Output "Missing Owner role."   
		Throw
	}
}
Catch {    
	Write-Output  $($AADUsername + " does not have Owner role assigned")
}
#endregion

#region connect to Azure and check if admin on Azure AD 
Try {
	# this depends on the previous segment completeing 
	$role = Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Company Administrator'}
	$isMember = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | Get-AzureADUser | Where-Object {$_.UserPrincipalName -eq $AADUsername}
	
	if ($isMember.UserType -eq "Member") {
		Write-Output $($AADUsername + " has " + $role.DisplayName + " role assigned")        
	} 
	else {
		Write-Output "Missing Owner role."   
		Throw
	}
}
Catch {    
	Write-Output  $($AADUsername + " does not have " + $role.DisplayName + " role assigned")
}
#endregion

#region check Microsoft.DesktopVirtualization resource provider has been registerred
Write-Output "Checking if required resource providers are installed..."
$wvdResourceProviderNames = "Microsoft.DesktopVirtualization","microsoft.visualstudio"
foreach ($resourceProvider in $wvdResourceProviderNames) {
	$states = (Get-AzResourceProvider -ProviderNamespace $resourceProvider).RegistrationState
	if ($states -contains 'NotRegistered' -or $states -contains 'Unregistered') {
		Write-Output "Resource provider '$resourceProvider' not registered. Registering" -Verbose
		Register-AzResourceProvider -ProviderNamespace $resourceProvider
	}
	else {
		Write-Output "Resource provider '$resourceProvider' already registered" -Verbose
	}
}
#endregion

#region check VNET
Write-Output "Validating vNet and subnet..."
Try {        
	$VNET = Get-AzVirtualNetwork -name $existingVnetName
	($VNET).AddressSpace.AddressPrefixes 
	Write-Output $("Found the VNET " + $VNET.Name)   
	
	# subner 
	If (($VNET).Subnets.Name -eq $existingSubnetName) {
		Write-Output $("Found the subnet " + $existingSubnetName)   
	}
	else {
		Throw "Subnet not found!"
	}
}
Catch {                
	Write-Output $("Did not find the VNET " + $VNET + " with subnet " + $existingSubnetName)     
	throw  "Virtual network not found."
}
#endregion

#region check firewall
Write-Output ('Veryfing firewall allows connection to reguired URLs...')

$safeUrls = "rdbroker.wvdselfhost.microsoft.com","prod.warmpath.msftcloudes.com","catalogartifact.azureedge.net","wvdportalstorageblob.blob.core.windows.net","login.windows.net","catalogartifact.azureedge.net","www.msftconnecttest.com","settings-win.data.microsoft.com","fs.microsoft.com","slscr.update.microsoft.com","production.diagnostics.monitoring.core.windows.net","production.billing.monitoring.core.windows.net","production.diagnostics.monitoring.core.windows.net","firstparty.monitoring.windows.net","monitoring.windows.net"

foreach($url in $safeUrls) {
    $var = test-netconnection $url -port 443

    if ($var.TcpTestSucceeded) {
    Write-Output "$url is reachable."
    } 
    else {
        Write-Output "$url cannot be reached."   
        Throw
    }    
}

$url = "kms.core.windows.net"
$var = test-netconnection $url -port 1688
if ($var.TcpTestSucceeded) {
Write-Output "$url is reachable."
} 
else {
    Write-Output "$url cannot be reached."   
    Throw
}

$url = "169.254.169.254"
$var = test-netconnection $url -port 80
if ($var.TcpTestSucceeded) {
Write-Output "$url is reachable."
} 
else {
    Write-Output "$url cannot be reached."   
    Throw
}

Write-Output ('End verification.')
#endregion

# Grant managed identity contributor role on subscription level
$identity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name "WVDServicePrincipal"
New-AzRoleAssignment -RoleDefinitionName "Contributor" -ObjectId $identity.PrincipalId -Scope "/subscriptions/$subscriptionId"
Start-Sleep -Seconds 5
