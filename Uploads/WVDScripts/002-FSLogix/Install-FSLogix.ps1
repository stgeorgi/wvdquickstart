#Requires -RunAsAdministrator


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
# 1 Extract FSLogix #
#####################
LogInfo("######################")
LogInfo("# 1. Extract FSLogix #")
LogInfo("######################")

$FSLogixArchivePath = Join-Path $PSScriptRoot "FSLogixApp.zip"

LogInfo("Expanding Archive $FSLogixArchivePath into $PSScriptRoot")
Expand-Archive -Path $FSLogixArchivePath -DestinationPath $PSScriptRoot
LogInfo("Archive expanded")

#####################
# 2 Install FSLogix #
#####################
LogInfo("######################")
LogInfo("# 2. Install FSLogix #")
LogInfo("######################")

# To get switches run cmd with '$path /?'

$Switches = "/passive /norestart"
$ExecutableName = "x64\Release\FSLogixAppsSetup.exe"
$FSLogixExePath = Join-Path $PSScriptRoot $ExecutableName

LogInfo("Trigger installation of file '$FSLogixExePath' with switches '$switches'")
$Installer = Start-Process -FilePath $FSLogixExePath -ArgumentList $Switches -Wait -PassThru
LogInfo("The exit code is $($Installer.ExitCode)")
