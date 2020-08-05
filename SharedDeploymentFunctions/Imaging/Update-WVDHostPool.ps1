<#
.SYNOPSIS
Run the Image Update process for the given host pool resource

.DESCRIPTION
Run the Image Update process for the given host pool resource
- Update the host pool

.PARAMETER orchestrationFunctionsPath
Mandatory. Path to the required functions

.PARAMETER HostPoolName
Mandatory. Name of the hostpool to process

.PARAMETER HostPoolRGName
Mandatory. Resource group of the hostpool to process

.PARAMETER LogoffDeadline
Mandatory. Logoff Deadline in yyyyMMddHHmm

.PARAMETER LogOffMessageTitle
Required. Title of the popup the users receive when they get notified of their dawning session cancelation 

.PARAMETER LogOffMessageBody
Required. Message of the popup the users receive when they get notified of their dawning session cancelation

.PARAMETER TimeDifference
Offset to UTC in hours

.PARAMETER DeleteVM
Optional. Controls whether or not to Delete the VM (Very Destructive). Defaults to false.

.PARAMETER MarketplaceImageVersion
Optional. Version of the used marketplace image. Mandatory if 'CustomImageReferenceId' is not provided.

.PARAMETER CustomImageReferenceId
Optional. Full Reference to Custom Image.
/subscriptions/<SubscriptionID>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Compute/galleries/<ImageGalleryName>/images/<ImageDefinitionName>/versions/<version>
Mandatory if 'MarketplaceImageVersion' is not provided.

.PARAMETER LogAnalyticsWorkspaceId
Optional. Resource id for a deployed LA workspace

.PARAMETER LogAnalyticsPrimaryKey
Optional. Primary key for a deployed LA workspace

.PARAMETER Confirm
Optional. Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Optional.  Dry run of the script

.EXAMPLE
Invoke-UpdateHostPool @functionInput

Invoke the update host pool orchestration script with the given parameters
#>
function Update-WVDHostPool {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $orchestrationFunctionsPath,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolRGName,

        [Parameter(Mandatory = $true)]
        [string] $LogOffMessageTitle,

        [Parameter(Mandatory = $true)]
        [string] $LogOffMessageBody,
    
        [Parameter(Mandatory = $true)]
        [string]$TimeDifference,

        [Parameter(Mandatory = $false)]
        [boolean]$DeleteVM = $false,

        [Parameter(ParameterSetName = 'MarketPlaceImage', Mandatory = $true)]
        [string]$Version,

        [Parameter(ParameterSetName = 'CustomSIGImage', Mandatory = $true)]
        [string]$CustomImageReferenceId,

        [Parameter(mandatory = $false)]
        [string] $LogAnalyticsWorkspaceId,

        [Parameter(mandatory = $false)]
        [string] $LogAnalyticsPrimaryKey
    )

    # Setting ErrorActionPreference to stop script execution when error occurs
    $ErrorActionPreference = "Stop"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #region SharedFunctions

    function Add-LogEntry {
        <#
    .SYNOPSIS
    Add logs to log analytics workspace
    #>
        param(
            [Parameter(mandatory = $true)]
            [PSCustomObject]$LogMessageObj,

            [Parameter(mandatory = $false)]
            [string]$LogAnalyticsWorkspaceId,

            [Parameter(mandatory = $false)]
            [string]$LogAnalyticsPrimaryKey,

            [Parameter(mandatory = $false)]
            [string]$LogType = 'WVDHostpoolUpdate_CL',

            [Parameter(mandatory = $false)]
            $TimeDifference
        )

        Write-Output $LogMessageObj.msg

        if ($LogAnalyticsWorkspaceId -and $LogAnalyticsPrimaryKey -and $TimeDifference) {
            foreach ($Key in $LogMessage.Keys) {
                switch ($Key.substring($Key.Length - 2)) {
                    '_s' { $sep = '"'; $trim = $Key.Length - 2 }
                    '_t' { $sep = '"'; $trim = $Key.Length - 2 }
                    '_b' { $sep = ''; $trim = $Key.Length - 2 }
                    '_d' { $sep = ''; $trim = $Key.Length - 2 }
                    '_g' { $sep = '"'; $trim = $Key.Length - 2 }
                    default { $sep = '"'; $trim = $Key.Length }
                }
                $LogData = $LogData + '"' + $Key.substring(0, $trim) + '":' + $sep + $LogMessageObj.Item($Key) + $sep + ','
            }
            $TimeStamp = Convert-UTCtoLocalTime -TimeDifference $TimeDifference
            $LogData = $LogData + '"TimeStamp":"' + $timestamp + '"'

            #Write-Verbose "LogData: $($LogData)"
            $json = "{$($LogData)}"

            $PostResult = Send-OMSAPIIngestionFile -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body "$json" -logType $LogType -TimeStampField "TimeStamp"
            #Write-Verbose "PostResult: $($PostResult)"
            if ($PostResult -ne "Accepted") {
                Write-Error "Error posting to OMS - $PostResult"
            }
        }
    }

    function Convert-UTCtoLocalTime {
        <#
    .SYNOPSIS
    Convert from UTC to Local time
    #>
        param(
            [Parameter(mandatory = $true)]
            [string]$TimeDifference
        )

        $UniversalTime = (Get-Date).ToUniversalTime()
        $TimeDifferenceMinutes = 0
        if ($TimeDifference -match ":") {
            $TimeDifferenceHours = $TimeDifference.Split(":")[0]
            $TimeDifferenceMinutes = $TimeDifference.Split(":")[1]
        }
        else {
            $TimeDifferenceHours = $TimeDifference
        }
        #Azure is using UTC time, justify it to the local time
        $ConvertedTime = $UniversalTime.AddHours($TimeDifferenceHours).AddMinutes($TimeDifferenceMinutes)
        return $ConvertedTime
    }

    function Remove-AzVirtualMachine {
        <#
	.SYNOPSIS
		This function is used to remove Azure VMs as well as attached disks. By default, this function creates a job
		due to the time it takes to remove an Azure VM.
		
	.EXAMPLE
		PS> Get-AzVm -Name 'BAPP07GEN22' | Remove-AzVirtualMachine
	
		This example removes the Azure VM BAPP07GEN22 as well as any disks attached to it.
		
	.PARAMETER VMName
		The name of an Azure VM. This has an alias of Name which can be used as pipeline input from the Get-AzureRmVM cmdlet.
	
	.PARAMETER ResourceGroupName
		The name of the resource group the Azure VM is a part of.
	
	.PARAMETER Wait
		if you'd rather wait for the Azure VM to be removed before returning control to the console, use this switch parameter.
		if not, it will create a job and return a PSJob back.
	#>
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
        param
        (
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [Alias('Name')]
            [string]$VMName,
		
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
            [ValidateNotNullOrEmpty()]
            [string]$ResourceGroupName,

            [Parameter()]
            [pscredential]$Credential,

            [Parameter()]
            [ValidateNotNullOrEmpty()]
            [switch]$Wait,
        
            [Parameter(mandatory = $false)]
            [PSCustomObject]$LAInputObject
        )
        Process {
            $scriptBlock = {
                param ($VMName, $ResourceGroupName)
                $commonParams = @{
                    'Name'              = $VMName;
                    'ResourceGroupName' = $ResourceGroupName
                }
                $vm = Get-AzVm @commonParams
                
                #region Remove the boot diagnostics disk
                if ($vm.DiagnosticsProfile.bootDiagnostics) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing boot diagnostics storage container associated with $($VMName)" }	
                    $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
                    if ($vm.Name.Length -gt 9) {
                        $i = 9
                    }
                    else {
                        $i = $vm.Name.Length - 1
                    }

                    #region GettheVMID
                    $azResourceParams = @{
                        'ResourceName'      = $VMName
                        'ResourceType'      = 'Microsoft.Compute/virtualMachines'
                        'ResourceGroupName' = $ResourceGroupName
                    }
                    $vmResource = Get-AzResource @azResourceParams
                    $vmId = $vmResource.Properties.VmId
                    #endregion
                    $vmnameNoSpecialCharacters = $vm.name -replace '[^\p{L}\p{Nd}]', ''
                    $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vmnameNoSpecialCharacters.ToLower().Substring(0, $i), $vmId)
                    $diagSaRg = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
                    $saParams = @{
                        'ResourceGroupName' = $diagSaRg
                        'Name'              = $diagSa
                    }
                    
                    Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object { $_.Name -eq $diagContainerName } | Remove-AzStorageContainer -Force
                }
                #endregion
            
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the Azure VM named $($VMName)" }
                $null = $vm | Remove-AzVM -Force
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the Network Interface of the VM Named $($VMName)" }	
                foreach ($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                    $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                    Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                    foreach ($ipConfig in $nic.IpConfigurations) {
                        if ($null -ne $ipConfig.PublicIpAddress) {
                            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the Public IP Address of the VM named $($VMName)" }	
                            Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                        } 
                    }
                } 
            
                ## Remove the OS disk
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the OS Disk for the VM named $($VMName)" }	
                if ('Uri' -in $vm.StorageProfile.OSDisk.Vhd) {
                    ## Not managed
                    $osDiskId = $vm.StorageProfile.OSDisk.Vhd.Uri
                    $osDiskContainerName = $osDiskId.Split('/')[-2]

                    ## TODO: Does not account for resouce group 
                    $osDiskStorageAcct = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $osDiskId.Split('/')[2].Split('.')[0] }
                    $osDiskStorageAcct | Remove-AzStorageBlob -Container $osDiskContainerName -Blob $osDiskId.Split('/')[-1]

                    #region Remove the status blob
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the OS Disk Status Blob for VM named $($VMName)" }
                    $osDiskStorageAcct | Get-AzStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzStorageBlob
                    #endregion
                }
                else {
                    ## managed
                    Get-AzDisk | Where-Object { $_.ManagedBy -eq $vm.Id } | Remove-AzDisk -Force
                }
            
                ## Remove any other attached disks
                if ('DataDiskNames' -in $vm.PSObject.Properties.Name -and @($vm.DataDiskNames).Count -gt 0) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing Data Disks for VM named $($VMName)" }
                    foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri) {
                        $dataDiskStorageAcct = Get-AzStorageAccount -Name $uri.Split('/')[2].Split('.')[0]
                        $dataDiskStorageAcct | Remove-AzStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1]
                    }
                }
            }
			
            if ($Wait.IsPresent) {
                & $scriptBlock -VMName $VMName -ResourceGroupName $ResourceGroupName
            }
            else {
                $jobParams = @{
                    'ScriptBlock'  = $scriptBlock
                    'ArgumentList' = @($VMName, $ResourceGroupName)
                    'Name'         = "Azure VM $VMName Removal"
                }
                Start-Job @jobParams 
            }
        }
    }

    function Stop-SessionHost {
        <#
    .SYNOPSIS
    Stop the Session Host
    #>
        param(
            [Parameter(mandatory = $true)]
            [string]$VMName,
	
            [Parameter(mandatory = $false)]
            [PSCustomObject]$LAInputObject
        )

        try {
            Get-AzVM -Name $VMName | Stop-AzVM -Force -AsJob | Out-Null
        }
        catch {
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Failed to stop Azure VM: $($VMName) with error: $($_.exception.message)" }	
            exit
        }
    }

    #endregion

    if ($LogAnalyticsWorkspaceId -and $LogAnalyticsPrimaryKey) {
        Write-Output "Run with LA-Workspace"
        $LAInputObject = @{
            LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId 
            LogAnalyticsPrimaryKey  = $LogAnalyticsPrimaryKey 
            TimeDifference          = $UTCOffset
        }
    }
    else {
        Write-Output "Run without LA-Workspace"
        $LAInputObject = @{ }
    }

    ##################
    ### MAIN LOGIC ###
    ##################

    # Calculate Image Version from Parameters
    if ($PSCmdlet.ParameterSetName -eq 'MarketPlaceImage') {
        [Version]$TargetImageVersion = $Version
    }
    else {
        $ACustomImageID = $CustomImageReferenceId.Split("/")
        [Version]$TargetImageVersion = $ACustomImageID[$ACustomImageID.Count - 1]
    }

    # Converting date time from UTC to Local
    $CurrentDateTime = Convert-UTCtoLocalTime -TimeDifference $UTCOffset
    # Get DeadlineTime
    $DeadlineDateTime = [System.DateTime]::ParseExact($LogoffDeadline, 'yyyyMMddHHmm', $null)

    # Set Force Logoff if at or after deadline
    if ($CurrentDateTime -ge $DeadlineDateTime) {
        $DeadlinePassed = $true
    }

    # Validate and get HostPool info
    $HostPool = $null
    try {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Get Hostpool info: `"$($HostPoolName)`" in resource group: `"$HostpoolRGName`"." }
        $HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $HostpoolRGName
        if (!$HostPool) {
            throw $HostPool
        }
    }
    catch {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Hostpoolname `"$($HostpoolName)`" does not exist. Ensure that you have entered the correct values." }
        exit
    }

    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Starting WVD Hostpool Update: Current Date Time is: $CurrentDateTime" }

    # Get list of session hosts in hostpool
    $SessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolRGName -ErrorAction Stop | Sort-Object SessionHostName
    # Check if the hostpool has session hosts
    if (!$SessionHosts) {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are no session hosts in the `"$($HostpoolName)`" Hostpool." }
        exit
    }
    $SessionHostCount = $SessionHosts.Count
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Processing hostpool $($HostpoolName) which contains $SessionHostCount session hosts." }

    # Initialize variables for tracking running old session hosts.
    $RunningOldHosts = 0
    $RunningOldHosts = @()
    [int]$NumberOfRunningHosts = 0

    # Analyze the SessionHosts and Azure VM instances for applicability and to determine power state. Delete any turned off VMs if DeleteVM is specified.
    foreach ($SessionHost in $SessionHosts) {
        $SessionHostName = $SessionHost.Name.Split("/")[1]
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Analyzing `"$($SessionHostName)`" for image version and power state." }
        $VMName = $SessionHostName.split('.')[0]
        $VMInstance = Get-AzVM -Status -Name $VMName

        # Check if VM has new Image or old image based on ImageVersion tag Value
        if ($VMInstance.Tags.ImageVersion -eq $TargetImageVersion) {
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$VMName is based on correct image version, skipping this VM." }
            Continue
        }

        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$VMName is not based on correct image version." }

        # Set Drain Mode if not already set
        if ($SessionHost.AllowNewSession) {
            Update-AzWvdSessionHost -Name $SessionHostName -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -AllowNewSession:$False | Out-Null
        }
    
        if ($SessionHostName.ToLower().Contains($VMInstance.Name.ToLower())) {
            # Check if the Azure vm is running       
            if ($VMInstance.PowerState -eq "VM running") {
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "`"$($VMName)`" is currently powered on." }
                $NumberOfRunningHosts = $NumberOfRunningHosts + 1
                $RunningOldHosts += $SessionHost
            }
            else {
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "`"$($VMName)`" is currently powered off." }
                if ($DeleteVM -eq $True -and $DeadlinePassed -eq $true) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The VM: `"$($VMName)`" is being removed from hostpool and deleted." }
                    Get-AzVM -Name $VMName | Remove-AzVirtualMachine
                    Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                }
            }
        }
    }

    # Process powered on VMs to determine if there are user sessions. If no sessions, stop (or delete VM). If sessions, then send message to active sessions or forcefully logoff users if Deadline has passed.
    # Stop or Delete VM after all user sessions are removed.
    if ($NumberofRunningHosts -gt 0) {
        $SessionHost = $null
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Current number of running hosts that need to be stopped: $NumberOfRunningHosts" }
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Now processing the old Running hosts." }

        foreach ($SessionHost in $RunningOldHosts) {
            $SessionHostName = $SessionHost.Name.Split("/")[1]
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Processing `"$($SessionHostName)`"." }
            $VMName = $SessionHostName.split('.')[0]
            $VMInstance = Get-AzVM -Status -Name $VMName
            if ($SessionHostName.ToLower().Contains($VMInstance.Name.ToLower())) {   
                $UserSessions = Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostPoolRGName -SessionHostName $SessionHostName
                $ExistingSessions = $UserSessions.Count         
                if ($ExistingSessions -gt 0) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are $ExistingSessions user sessions on $SessionHostName." }
                    If ($DeadlinePassed) {
                        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Logging off all users because deadline has passed." }
                        foreach ($Session in $UserSessions) {
                            $SplitSessionID = $Session.Id.Split("/")
                            $SessionID = $SplitSessionID[$SplitSessionID.Count - 1]
                            try {
                                Remove-AzWvdUserSession -ResourceGroupName $HostPoolRGName -HostPoolName $HostpoolName -SessionHostName $SessionHostName -Id $SessionId -Force
                                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Forcefully logged off the user: $($Session.ActiveDirectoryUserName | Out-String)" }
                            }
                            catch {
                                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Failed to log off user with error: $($_.exception.message)" }
                            }
                        }

                        # Check for User Sessions every 5 seconds and wait for them to equal 0 or 30 sec timeout to expire.
                        $timer = 0
                        do {
                            $ExistingSessions = (Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostPoolRGName -SessionHostName $SessionHostName).Count
                            $timer = $timer + 5
                            Start-Sleep -seconds 5
                        } until (($ExistingSessions -eq 0) -or ($timer -ge 30))

                        # Don't want to stop or delete a VM if we couldn't remove existing sessions because it could cause profile corruption or the user(s) may not be able to logon afterwards.
                        If ($ExistingSessions -eq 0) {
                            if ($DeleteVM -eq $True) {
                                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The stopped VM: $VMName is being removed from hostpool and deleted." }
                                Get-AzVM -Name $VMName | Remove-AzVirtualMachine
                                Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                            }
                            else {
                                # Shutdown the Azure VM
                                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Stopping Azure VM: $VMName." }
                                Stop-SessionHost @LAInputObject -VMName $VMName
                            }
                        }
                        else {
                            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Unable to stop Azure VM: `"$($VMName)`" because it still has existing sessions." }
                        }
                    }
                    else {
                        foreach ($Session in $UserSessions) {
                            $SplitSessionID = $Session.Id.Split("/")
                            $SessionID = $SplitSessionID[$SplitSessionID.Count - 1]
                            write-output "User $($Session.ActiveDirectoryUserName) has Session ID: $SessionID"
                            if ($session.SessionState -eq "Active") {
                                # Send notification
                                try {
                                    Send-AzWvdUserSessionMessage -ResourceGroupName $HostPoolRGName -HostPoolName $HostpoolName -SessionHostName $SessionHostName -UserSessionId $SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will be logged off automatically at $($DeadlineDateTime)." -ErrorAction Stop
                                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Sent a log off message to user: $($Session.ActiveDirectoryUsername | Out-String)" }
                                }
                                catch {
                                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Failed to send message to user with error: $($_.exception.message)" }
                                }
                            }
                        }   
                    }
                }
                else {
                    if ($DeleteVM -eq $True -and $DeadlinePassed -eq $true) {
                        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The $VMName is being removed from hostpool and deleted." }
                        Get-AzVM -Name $VMName | Remove-AzVirtualMachine
                        Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                    }
                    else {
                        # Shutdown the Azure VM
                        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are no user sessions on $SessionHostName." }
                        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Stopping Azure VM: `"$($VMName)`"." }
                        Stop-SessionHost @LAInputObject -VMName $VMName
                    }
                }
            }    
        }
    }
    else {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "No remaining Old Hosts Need to be stopped. Exiting Script." }
    }
}