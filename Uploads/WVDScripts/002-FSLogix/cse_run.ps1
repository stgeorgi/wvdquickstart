[CmdletBinding(SupportsShouldProcess = $true)]
param (
    # [Parameter(Mandatory = $true)]
    # [ValidateNotNullOrEmpty()]
    # [string] $storageAccountKey,

    [Parameter(Mandatory = $false)]
    [Hashtable] $DynParameters,

    [Parameter(Mandatory = $false)]
    [string] $AzureAdminUpn,

    [Parameter(Mandatory = $false)]
    [string] $AzureAdminPassword,

    [Parameter(Mandatory = $false)]
    [string] $domainJoinPassword,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    #[string] $ConfigurationFilePath = (Join-Path $PSScriptRoot "fslogix.parameters.json")
    [string] $ConfigurationFileName = "fslogix.parameters.json"
)

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
Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\FSLogix" # inside "executionCustomScriptExtension_$scriptName_$date.log"

LogInfo("###################")
LogInfo("## 0 - LOAD DATA ##")
LogInfo("###################")
#$storageaccountkey = $DynParameters.storageaccountkey

$ConfigurationFilePath= Join-Path $PSScriptRoot $ConfigurationFileName

$ConfigurationJson = Get-Content -Path $ConfigurationFilePath -Raw -ErrorAction 'Stop'

try { $FSLogixConfig = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
catch {
    Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
}

LogInfo("##################")
LogInfo("## 1 - EVALUATE ##")
LogInfo("##################")
foreach ($config in $FSLogixConfig.fslogix) {

    if ($config.installFSLogix) {
        LogInfo("########################")
        LogInfo("## 2 - INSTALL FLOGIX ##")
        LogInfo("########################")
        LogInfo("Trigger FSLogix")

        # & "$PSScriptRoot\Install-FSLogix.ps1"
        if ($PSCmdlet.ShouldProcess("FSLogix", "Install")) {
            & "$PSScriptRoot\Install-FSLogix.ps1"
            LogInfo("FSLogix installed")
        }
    }

    if ($config.configureFSLogix) {
        LogInfo("###########################")
        LogInfo("## 3 - CONFIGURE FSLOGIX ##")
        LogInfo("###########################")
        foreach ($key in $config.profileContainerKeys) {
            LogInfo($key.Name)
            LogInfo($key.Type)
            LogInfo($key.Value)
        }

        $($config.profileContainerKeys).GetType() | Format-Table
        Write-Verbose "Before function count: $($testArr.Count)"

        # & "$PSScriptRoot\Configure-FSLogix.ps1" $config.profileContainerKeys
        if ($PSCmdlet.ShouldProcess("FSLogix", "Set")) {
            & "$PSScriptRoot\Set-FSLogix.ps1" $config.profileContainerKeys
            LogInfo("FSLogix configured")
        }
    }

    if ($config.NTFSPermission) {
        LogInfo("######################################################")
        LogInfo("## 4 - Set NTFS Permission on the share for FSLogix ##")
        LogInfo("######################################################")
        LogInfo($config.fileShareName)
        LogInfo($config.fileShareStorageAccountName)
        LogInfo($config.domain)
        LogInfo($config.targetGroup)

        $fileShareUri = "\\{0}.file.core.windows.net\{1}" -f $config.fileShareStorageAccountName, $config.fileShareName
        $storageAccountKey = ConvertTo-SecureString -String $DynParameters.storageaccountkey -AsPlainText -Force
        
        $fileShareInputObject = @{
            storageAccountName = $config.fileShareStorageAccountName
            fileShareUri       = $fileShareUri
            storageAccountKey  = $storageAccountKey
            domain             = $config.domain
            targetGroup        = $config.targetGroup
        }
        $fileShareInputObject.Keys | ForEach-Object { LogInfo("Drive: Use param: '{0}' with value '{1}'" -f $_, $fileShareInputObject[$_]) }

        # & "$PSScriptRoot\Set-NTFSPermissions.ps1" @fileShareInputObject
        if ($PSCmdlet.ShouldProcess("NTFS Permissions on the share", "Set")) {
            & "$PSScriptRoot\Set-NTFSPermissions.ps1" @fileShareInputObject
            LogInfo("Permissions set")
        }
    }
}