<#

.DESCRIPTION
This script is ran by the main ARM template as a custom script extension on the domain controller vm to create an AD user group and an AD user (a test user for the WVD environment). 
This user then gets synced to Azure Active Directory using the ADSync module.

.PARAMETER domainName
Name of the domain 

.PARAMETER targetGroup
Name of the test user group to be created

.PARAMETER artifactsLocation
URL of the GitHub repository

.PARAMETER domainUsername
username of the domain join account

.PARAMETER domainPassword
password of the domain join account. Not stored in any logs.

.PARAMETER devOpsName
Name of the DevOps organization to generate the test user password

#>

[CmdletBinding(SupportsShouldProcess = $true)]
$ConfigurationFileName = "users.parameters.json"

# Parameters below are passed by the main ARM template
$domainName = $args[0]
$targetGroup = $args[1]
$artifactsLocation = $args[2]
$domainUsername = $args[3]
$domainPassword = $args[4]
$devOpsName = $args[5]
#####################################

##########
# Helper #
##########
#region Functions
function LogInfo($message) {
    Log "Info" $message
}

function LogError($message) {
    Log "Error" $message
}

function LogSkip($message) {
    Log "Skip" $message
}

function LogWarning($message) {
    Log "Warning" $message
}

function Log {

    <#
    .SYNOPSIS
   Creates a log file and stores logs based on categories with tab seperation

    .PARAMETER category
    Category to put into the trace

    .PARAMETER message
    Message to be loged

    .EXAMPLE
    Log 'Info' 'Message'

    #>

    Param (
        $category = 'Info',
        [Parameter(Mandatory = $true)]
        $message
    )

    $date = get-date
    $content = "[$date]`t$category`t`t$message`n"
    Write-Verbose "$content" -verbose

    if (! $script:Log) {
        $File = Join-Path $env:TEMP "log.log"
        Write-Error "Log file not found, create new $File"
        $script:Log = $File
    }
    else {
        $File = $script:Log
    }
    Add-Content $File $content -ErrorAction Stop
}

function Set-Logger {
    <#
    .SYNOPSIS
    Sets default log file and stores in a script accessible variable $script:Log
    Log File name "executionCustomScriptExtension_$date.log"

    .PARAMETER Path
    Path to the log file

    .EXAMPLE
    Set-Logger
    Create a logger in
    #>

    Param (
        [Parameter(Mandatory = $true)]
        $Path
    )

    # Create central log file with given date

    $date = Get-Date -UFormat "%Y-%m-%d %H-%M-%S"

    $scriptName = (Get-Item $PSCommandPath ).Basename
    $scriptName = $scriptName -replace "-", ""

    Set-Variable logFile -Scope Script
    $script:logFile = "executionCustomScriptExtension_" + $scriptName + "_" + $date + ".log"

    if ((Test-Path $path ) -eq $false) {
        $null = New-Item -Path $path -type directory
    }

    $script:Log = Join-Path $path $logfile

    Add-Content $script:Log "Date`t`t`tCategory`t`tDetails"
}
#endregion


## MAIN
#Set-Logger "C:\WindowsAzure\CustomScriptExtension\Log" # inside "executionCustomScriptExtension_$date.log"
Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\UserConfig" # inside "executionCustomScriptExtension_$scriptName_$date.log"

LogInfo("## 0 - LOAD DATA ##")

$url = $($artifactsLocation + "/Modules/ARM/UserCreation/Parameters/users.parameters.json")
Invoke-WebRequest -Uri $url -OutFile "C:\users.parameters.json"
$ConfigurationJson = Get-Content -Path "C:\users.parameters.json" -Raw -ErrorAction 'Stop'

try { $UserConfig = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
catch {
    Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
}

Import-Module activedirectory

$adminUsername = $domainName + "\" + $domainUsername
if ((new-object directoryservices.directoryentry "",$adminUsername,$domainPassword).psbase.name -ne $null)
{
    LogInfo("Valid domain join credentials") 
}
else
{
    Write-Error "Invalid domain join credentials entered" -ErrorAction 'Stop'
}

foreach ($config in $UserConfig.userconfig) {

    if ($config.createGroup) {
        LogInfo("## 1 - Create user group ##")
          
        $userGroupName = $targetGroup

        LogInfo("Create user group...")

        $existingGroup = Get-ADGroup -Filter "Name -eq '$($userGroupName)'"
        if($existingGroup -eq $null) {
            New-ADGroup `
            -SamAccountName $userGroupName `
            -Name "$userGroupName" `
            -DisplayName "$userGroupName" `
            -GroupScope "Global" `
            -GroupCategory "Security" -Verbose
        }
        else {
            LogInfo("User group $userGroupName already exists, using that existing group.")
        }

        LogInfo("Create user group completed.")
    }
    
    if ($config.createUser) {
        LogInfo("## 2 - Create user    ##")

        $userName = $config.userName
        $password = $devOpsName.substring(13) + '!'

        $existingUser = Get-ADUser -Filter "Name -eq '$($userName)'"
        if($existingUser -ne $null) {
            LogInfo("Existing user with the username $userName found. Removing that user...")
            Set-ADUser -Identity $userName -UserPrincipalName $($userName + "temp@" + $domainName)
            Remove-ADUser -Identity $userName -Confirm:$False
            Import-Module ADSync -Force
            Start-ADSyncSyncCycle -PolicyType Delta -Verbose
            Start-Sleep -Seconds 90
            LogInfo("Existing user removed.")
        }

        LogInfo("Creating user...")

        New-ADUser `
        -SamAccountName $userName `
        -UserPrincipalName $($userName + "@" + $domainName) `
        -Name "$userName" `
        -GivenName $userName `
        -Surname $userName `
        -Enabled $True `
        -ChangePasswordAtLogon $False `
        -DisplayName "$userName" `
        -AccountPassword (convertto-securestring $password -AsPlainText -Force) -Verbose

        LogInfo("Create user completed.")
    }

    if ($config.assignUsers) {
        LogInfo("## 3 - Assign users to group ##")

        Add-ADGroupMember -Identity $targetGroup -Members $config.userName
        LogInfo("User assignment to group completed.")
    }

    if ($config.syncAD) {
        LogInfo("## 4 - Sync new users & group with AD Sync ##")

        Import-Module ADSync -Force
        Start-ADSyncSyncCycle -PolicyType Delta -Verbose
    }
}
