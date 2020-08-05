[CmdletBinding(SupportsShouldProcess = $true)]
param (
    # [Parameter(Mandatory = $true)]
    # [ValidateNotNullOrEmpty()]
    # [string] $storageAccountKey,

    [Parameter(Mandatory = $false)]
    [Hashtable] $DynParameters,

    [Parameter(Mandatory = $false)]
    [string] $AzureAdminUpn,

    [Parameter(Mandatory = $true)]
    [string] $AzureAdminPassword,

    [Parameter(Mandatory = $true)]
    [string] $domainJoinPassword,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $ConfigurationFileName = "azfiles.parameters.json"
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
Set-Logger "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\executionLog\azfilesconfig" # inside "executionCustomScriptExtension_$scriptName_$date.log"

LogInfo("###################")
LogInfo("## 0 - LOAD DATA ##")
LogInfo("###################")
#$storageaccountkey = $DynParameters.storageaccountkey

$ConfigurationFilePath= Join-Path $PSScriptRoot $ConfigurationFileName

$ConfigurationJson = Get-Content -Path $ConfigurationFilePath -Raw -ErrorAction 'Stop'

try { $azfilesconfig = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
catch {
    Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
}

LogInfo("##################")
LogInfo("## 1 - EVALUATE ##")
LogInfo("##################")
foreach ($config in $azfilesconfig.azfilesconfig) {
    if ($config.enableAzureFiles) {
        if ($config.identityApproach -eq "AD") {
            LogInfo("############################")
            LogInfo("## 2 - Enable Azure Files ##")
            LogInfo("############################")
            
            LogInfo("Set Execution Policy...")
            #Change the execution policy to unblock importing AzFilesHybrid.psm1 module
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

            #Define parameters
            $ResourceGroupName = $config.ResourceGroupName
            $ResourceGroupName = $ResourceGroupName.Replace('"', "'")
            $StorageAccountName = $config.StorageAccountName
            $StorageAccountName = $StorageAccountName.Replace('"', "'")

            # Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
            # You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
            # You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
            # Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.

            $split = $config.domainName.Split(".")
            $username = $($split[0] + "\" + $config.domainJoinUsername)
            $scriptPath = $($PSScriptRoot + "\setup.ps1")
            Set-Location $PSScriptRoot

            LogInfo("Using PSExec, set execution policy for the admin user")
            $scriptBlock = { .\psexec /accepteula -h -u $username -p $domainJoinPassword -c "powershell.exe" Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force }
            Invoke-Command $scriptBlock -Verbose

            LogInfo("Execution policy for the admin user set. Now joining the storage account through another PSExec command... This command takes roughly 5 minutes")
            $scriptBlock = { .\psexec /accepteula -h -u $username -p $domainJoinPassword -c "powershell.exe" "$scriptPath -S $StorageAccountName -RG $ResourceGroupName -U $AzureAdminUpn -P $AzureAdminPassword" }
            LogInfo("Scriptblock to execute: $scriptBlock")
            Invoke-Command $scriptBlock -Verbose

            LogInfo("Azure Files Enabled!")
        }
        elseif ($config.identityApproach -eq "Azure AD DS") {
            LogInfo("Azure AD DS is used, for which the storage account has been enabled in the DevOps pipeline. No further action is needed in this Custom Script Extension")
        }
    }
}