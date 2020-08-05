[CmdletBinding(SupportsShouldProcess = $true)]
param (
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
    [string] $ExecutableName = "Teams_windows_x64.msi"

    #[Parameter(Mandatory = $false)]
    #[ValidateNotNullOrEmpty()]
    #[string] $Switches = "/S /D=${Env:ProgramFiles(x86)}\Notepad++\"
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

Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\Teams" # inside "executionCustomScriptExtension_$scriptName_$date.log"
$MSIPath = "$($PSScriptRoot)\$ExecutableName"
LogInfo("Installing teams from path $MSIPath")

LogInfo("Setting registry key Teams")
if ((Test-Path "HKLM:\Software\Microsoft\Teams") -eq $false) {
    New-Item -Path "HKLM:\Software\Microsoft\Teams" -Force
}
New-ItemProperty "HKLM:\Software\Microsoft\Teams" -Name "IsWVDEnvironment" -Value 1 -PropertyType DWord -Force
LogInfo("Set IsWVDEnvironment DWord to value 1 successfully.")

$scriptBlock = { msiexec /i $MSIPath /l*v "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\Teams\InstallLog.txt" ALLUSER=1 ALLUSERS=1 }
LogInfo("Invoking command with the following scriptblock: $scriptBlock")
LogInfo("Install logs can be found in the InstallLog.txt file in this folder.")
Invoke-Command $scriptBlock -Verbose

LogInfo("Teams was successfully installed")