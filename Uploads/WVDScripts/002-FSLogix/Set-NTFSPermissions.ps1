#Requires -RunAsAdministrator


<#
    Assign Storage Account File Share Permissions

    CSE based on instructions at:
        https://docs.microsoft.com/en-us/azure/storage/files/storage-files-active-directory-enable
        https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows

    Using New-PSDrive to mount the drive. A good alternative is 'net use'.

        # For a  not domain joined machine:
        net use $driveLetter \\$storageAccountName.file.core.windows.net\$fileShareName $storageAccountKey /user:Azure\$storageAccountName

        # For a domain joned machine (avoids keys):
        net use $driveLetter: \\$storageAccountName.file.core.windows.net\$fileShareName
#>

[cmdletbinding()]
param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Name of the storage account to interact with'
    )]
    [string] $storageAccountName,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Name of the file share within the storage account'
    )]
    [string] $fileShareUri,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Key to access storage account'
    )]
    [System.Security.SecureString] $storageAccountKey,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Domain containing the grop to assign permission for the file share. With or without ".onmicrosoft.com"'
    )]
    [string] $domain,

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Name of the group to assign file share access to'
    )]
    [string] $targetGroup,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Drive letter to mount the drive to'
    )]
    [string] $driveLetter = 'Y'
)


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
        [string] $Path
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

Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\FSLogix" # inside "executionCustomScriptExtension_$scriptName_$date.log"

# Mount the drive
LogInfo('###################')
LogInfo('# MOUNT THE DRIVE #')
LogInfo('###################')

# The value given to the root parameter of the New-PSDrive cmdlet is the host address for the storage account,
# <storage-account>.file.core.windows.net for Azure Public Regions. $fileShare.StorageUri.PrimaryUri.Host is
# used because non-Public Azure regions, such as sovereign clouds or Azure Stack deployments, will have different
# hosts for Azure file shares (and other storage resources).
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "AZURE\$($storageAccountName)", $storageAccountKey
# Transform https://<StorageAccountName>.file.core.windows.net/wvdprofile to '\\<StorageAccountName>.file.core.windows.net\wvdprofile'

$driveInputObject = @{
    Name       = $driveLetter
    PSProvider = 'FileSystem'
    Root       = $fileShareUri
    Credential = $credential
}
LogInfo("Try to get drive '$driveLetter'")
if (-not (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue)) {
    LogInfo('Mount Drive "{0}" from root "{1}"' -f $driveInputObject.Name, $driveInputObject.Root)
    try {
        New-PSDrive @driveInputObject -Persist -Verbose
    }
    catch {
        Write-Error $_.Exception.Message
        throw $_
    }

    $drive = Get-PSDrive -Name $driveLetter
    LogInfo("Drive mounted: {0}" -f ($drive | Format-List | Out-String))
}
else {
    LogInfo('Drive "{0}" from root "{1}" already mounted' -f $driveInputObject.Name, $driveInputObject.Root)
}

LogInfo('########################')
LogInfo('# SET NTFS PERMISSIONS #')
LogInfo('########################')

LogInfo('Cleanup domain name')
$domain = $domain.Replace('.onmicrosoft.com', '')

# Assign permissions
$command = "icacls {0}: /grant ('{1}\{2}:(M)'); icacls {0}: /grant ('Creator Owner:(OI)(CI)(IO)(M)'); icacls {0}: /remove ('Authenticated Users'); icacls {0}: /remove ('Builtin\Users')" -f $driveLetter, $domain, $targetGroup
LogInfo("Run ACL command: '$command'")
Invoke-Expression -Command $command
LogInfo("ACLs set")
LogInfo("Read ACLs")
$readCommand = "icacls {0}:" -f $driveLetter
LogInfo("Run command: '$readCommand'")
$info = Invoke-Expression -Command $readCommand
LogInfo($info | Format-List | Out-String)