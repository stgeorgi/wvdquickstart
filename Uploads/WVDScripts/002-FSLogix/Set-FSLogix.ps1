#Requires -RunAsAdministrator

<#
    Install and configure FSLogix

    CSE based on instructions at:
        https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-user-profile#configure-the-fslogix-profile-container
#>

[cmdletbinding()]

param(
    [parameter(Mandatory, ValueFromPipeline)]
    [object]$registryValues
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


Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\FSLogix" # inside "executionCustomScriptExtension_$scriptName_$date.log"

#####################
# Configure FSLogix #
#####################

Write-Verbose "In function count: $($testArr.Count)"
$testArr

LogInfo("###############################")
LogInfo("# 1. Retrieve Registry Values #")
LogInfo("###############################")
$fsLogixRegPath = "HKLM:\software\FSLogix"
$expectedReqKey = 'Profiles'
$expectedfsLogixRegKeyPath = Join-Path $fsLogixRegPath $expectedReqKey

LogInfo("############################")
LogInfo("# 2. Check Profiles RegKey #")
LogInfo("############################")

if (-not (Test-Path $expectedfsLogixRegKeyPath)) {
    LogInfo("RegexPath '$expectedfsLogixRegKeyPath' not existing. Creating")
    New-Item -Path $expectedfsLogixRegKeyPath -Force | Out-Null
}
else {
    LogInfo("RegexPath '$fsLogixRegPath' already existing. Creation skipped")
}

LogInfo("######################")
LogInfo("# 3. Creating Values #")
LogInfo("######################")

$registryValues | ForEach-Object {
    LogInfo('Creating entry "{0}" of type "{1}" with value "{2}" in path "{3}"' -f $_.Name, $_.Type, $_.Value, $expectedfsLogixRegKeyPath)
    $inputObject = @{
        Path         = $expectedfsLogixRegKeyPath
        Name         = $_.Name
        Value        = $_.Value
        PropertyType = $_.Type
    }
    New-ItemProperty @inputObject -Force | Out-Null
}