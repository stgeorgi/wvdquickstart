param(
	[string] [Parameter(Mandatory=$true)] $username,
	[string] [Parameter(Mandatory=$true)] $password,
	[string] [Parameter(Mandatory=$true)] $targetGroup,
	[string] [Parameter(Mandatory=$true)] $domainName,
	[string] [Parameter(Mandatory=$true)] $artifactsLocation 
)

#Install-Module AzureAD -Force
#Import-Module AzureAD -Force

$url = $($artifactsLocation + "/Modules/ARM/UserCreation/Parameters/users.parameters.json")
$response = Invoke-WebRequest -Uri $url
$ConfigurationJson = $response.content

try { $UserConfig = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
catch {
    Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
}

$ErrorActionPreference = 'Stop'

#$Credential = New-Object System.Management.Automation.PsCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))
#Connect-AzureAD -AzureEnvironmentName 'AzureCloud' -Credential $Credential

foreach ($config in $UserConfig.userconfig) {
	$userName = $config.userName
	$upn = $($userName + "@" + $domainName)
    if ($config.createGroup) { New-AzADGroup -DisplayName "$targetGroup" -MailNickname "$targetGroup" }
    if ($config.createUser) { New-AzADUser -UserPrincipalName $upn -Name "$userName" -MailNickname $userName -Password (convertto-securestring $config.password -AsPlainText -Force) }
    if ($config.assignUsers) { Add-AzADGroupMember -MemberUserPrincipalName  $upn -TargetGroupDisplayName $targetGroup }
    Start-Sleep -Seconds 1
}
