<#      
    .DESCRIPTION
    Main script performing the Windows VM extension deployment. Executed steps:
     - find all ZIP files in the downloaded folder (including subfolder).
     - extract all ZIP files to _deploy folder by also creating the folder.
     - each ZIP is extracted to a subfolder _deploy\<XXX>-<ZIP file name without extension> where XXX is a number starting at 000.
     - find all CSE_Run.ps1 files in _deploy subfolders.
     - execute all CSE_Run.ps1 scripts found in _deploy subfolders in the order of folder names and passing the DynParameters parameter from this script.
    .Parameter DynParameters
        Hashtable parameter enabling to pass Key-Value parameter pairs. Example: @{"Environment"="Prod";"Debug"="True"}        
#>

[CmdletBinding(DefaultParametersetName = 'None')]
param(

    [Parameter(Mandatory = $true)]
    [string] $AzureAdminUpn,

    [Parameter(Mandatory = $true)]
    [string] $AzureAdminPassword,

    [Parameter(Mandatory = $true)]
    [string] $domainJoinPassword,

    $p = "",    
    [Hashtable] [Parameter(Mandatory = $false)]
	$DynParameters
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
    Set-Variable logFile -Scope Script
    $script:logFile = "executionCustomScriptExtension_InitializeHost_$date.log"

    if ((Test-Path $path ) -eq $false) {
        $null = New-Item -Path $path -type directory
    }

    $script:Log = Join-Path $path $logfile

    Add-Content $script:Log "Date`t`t`tCategory`t`tDetails"
}
#endregion

Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog" # inside "executionCustomScriptExtension_$date.log"
$ErrorActionPreference = 'Stop'
LogInfo "Current working dir: $((Get-Location).Path)"

LogInfo "Unpacking zip files"

$zipPackages = Get-ChildItem -Filter "*.zip" -Recurse | sort -Property BaseName
if($zipPackages){
    LogInfo "Found $($zipPackages.count) zip packages"
}
else
{
    LogError "No zip files found in the directory"
}

$i=0
foreach ($zip in $zipPackages)
{
    LogInfo "Unpacking $($zip.FullName)"
    Expand-Archive -Path $zip.FullName -DestinationPath "_deploy\$(($i++).ToString("000"))-$($zip.BaseName)"
}
LogInfo "Unpacking completed - Searching for CSE_Run.ps1 files"

$PsScriptsToRun = Get-ChildItem -path "_deploy" -Filter "CSE_Run.ps1" -Recurse | sort -Property FullName

if($PsScriptsToRun){
    LogInfo "Found $($PsScriptsToRun.count) scripts"
}
else
{
    LogError "No scripts found in the directory"
}

foreach ($scr in $PsScriptsToRun)
{
    LogInfo "Running $($scr.FullName)"
    & $scr.FullName -DynParameters $DynParameters -AzureAdminUpn $AzureAdminUpn -AzureAdminPassword $AzureAdminPassword -domainJoinPassword $domainJoinPassword
}
LogInfo "Execution completed"