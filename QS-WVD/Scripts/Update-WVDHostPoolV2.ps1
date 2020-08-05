Param
(
    [Parameter(Mandatory=$true)]
    $HostPoolName,

    [Parameter(Mandatory=$true)]
    $HostPoolRGName,

    # Logoff Deadline in yyyyMMddHHmm
    [string]$LogoffDeadline,

    $LogOffMessageTitle,

    $LogOffMessageBody,
    
    # Time Difference between local time and UTC expressed in hh:mm format. Include "-" in front if negative value.
    # ex. 4:00 or -4:00
    [string]$UTCOffset,

    # Whether or not to Delete the VM (Very Destructive)
    [boolean]$DeleteVM,

    # MarketPlace Image Parameters
    [Parameter(ParameterSetName = 'MarketPlaceImage', Mandatory = $true)]
    [string]$Publisher,

    [Parameter(ParameterSetName = 'MarketPlaceImage', Mandatory = $true)]
    [string]$Offer,
    
    [Parameter(ParameterSetName = 'MarketPlaceImage', Mandatory = $true)]
    [string]$Sku,

    [Parameter(ParameterSetName = 'MarketPlaceImage', Mandatory = $true)]
    [string]$Version,

    # Full Reference to Custom Image.
    # /subscriptions/<SubscriptionID>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Compute/galleries/<ImageGalleryName>/images/<ImageDefinitionName>/versions/<version>
    [Parameter(ParameterSetName = 'CustomSIGImage', Mandatory = $true)]
    [string]$CustomImageReferenceId,

    [Parameter(mandatory = $false)]
	[string] $LogAnalyticsWorkspaceId,

	[Parameter(mandatory = $false)]
	[string] $LogAnalyticsPrimaryKey
)

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"
# Note: https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[int]$StatusCheckTimeOut = 60 * 10 # 10 min
[int]$SessionHostStatusCheckSleepSecs = 30

#install-module az.desktopvirtualization -AllowClobber -Force
#import-module az.desktopvirtualization

# $ctx = Get-AzContext
# $subscriptionId = $ctx.Subscription.Id
# $AADTenantID = $ctx.Tenant.Id

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
		$TimeDifferenceInHours
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
		$TimeStamp = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifferenceInHours
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

function Remove-AzVirtualMachine
{
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
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		[string]$VMName,
		
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
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
                } else {
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
                    
                Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object { $_.Name-eq $diagContainerName } | Remove-AzStorageContainer -Force
            }
            #endregion
            
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the Azure VM named $($VMName)" }
            $null = $vm | Remove-AzVM -Force
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Removing the Network Interface of the VM Named $($VMName)" }	
            foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                foreach($ipConfig in $nic.IpConfigurations) {
                    if($null -ne $ipConfig.PublicIpAddress) {
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
            } else {
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
        } else {
            $jobParams = @{
                'ScriptBlock'          = $scriptBlock
                'ArgumentList'         = @($VMName, $ResourceGroupName)
                'Name'                 = "Azure VM $VMName Removal"
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
		Get-AzVM | Where-Object { $_.Name -eq $VMName } | Stop-AzVM -Force -AsJob | Out-Null
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
		TimeDifference          = $TimeDifference
	}
} else {
	Write-Output "Run without LA-Workspace"
	$LAInputObject = @{ }
}

#####################
### MAIN LOGIC ###
#####################

# Calculate Image Version from Parameters
if ($PSCmdlet.ParameterSetName -eq 'MarketPlaceImage') {
    [Version]$TargetImageVersion = $Version
} else {
    $ACustomImageID = $CustomImageReferenceId.Split("/")
    [Version]$TargetImageVersion = $ACustomImageID[$ACustomImageID.Count-1]
}

# Converting date time from UTC to Local
$CurrentDateTime = Convert-UTCtoLocalTime -TimeDifference $UTCOffset
# Get DeadlineTime
$DeadlineDateTime = [System.DateTime]::ParseExact($LogoffDeadline,'yyyyMMddHHmm',$null)

if ($CurrentDateTime -ge $DeadlineDateTime) {
    $DeadlinePassed = $true
}

# Validate and get HostPool info
$HostPool = $null
try {
    Write-Log "Get Hostpool info: $HostPoolName in resource group: $ResourceGroupName"
    $HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName
    if (!$HostPool) {
        throw $HostPool
    }
}
catch {
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Hostpoolname '$HostpoolName' does not exist. Ensure that you have entered the correct values." }
	exit
}

# Ensure HostPool is a Pooled type
if ($HostPool.LoadBalancerType -eq 'Persistent') {
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Hostpoolname '$HostpoolName' is not a pooled host pool. This script does not support personal host pools." }
	exit
}

Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Starting WVD Hostpool Update: Current Date Time is: $CurrentDateTime" }

# Get list of session hosts in hostpool
$SessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolRGName | Sort-Object SessionHostName
# Check if the hostpool has session hosts
if (!$SessionHosts) {
	Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are no session hosts in `"$($HostpoolName)`"." }
	exit
}

Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Processing hostpool $($HostpoolName) with $($SessionHosts.Count) session hosts." }

# Initialize Variables
Number of session hosts that are running
[int]$nRunningVMs = 0
# Object that will contains all session host objects and VM instance objects that are not tagged with target imageversion.
$OldVMs = @{ }

# Populate all session hosts objects
foreach ($SessionHost in $SessionHosts) {
    $SessionHostName = $SessionHost.Name.Split('/')[1].ToLower()
    $OldVMs.Add($SessionHostName.Split('.')[0], @{ 'SessionHostName' = $SessionHostName; 'SessionHost' = $SessionHost; 'Instance' = $null })
}

# Get all Azure VM objects, check host status for imageversion tag and user session info. Follow Azure scripting best practices to only query once.

foreach ($VMInstance in (Get-AzVM -Status)) {
    if (!$OldVMs.ContainsKey($VMInstance.Name.ToLower())) {
        # This VM is not a WVD session host in this hostpool.
        continue
    }
    $VMName = $VMInstance.Name.ToLower()
    Try {
        $ImageVersion = $VMInstance.Tags.ImageVersion
        if ($ImageVersion -eq $TargetImageVersion) {
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$VMName is already using correct image version, skipping this VM." }
            $OldVMs.Remove($VMName)
            continue
        }
    } Catch {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$($VMName) does not have an image version tag. Will process this VM for shutdown or removal from hostpool." }
    }
   
    $OldVM = $OldVMs[$VMName]
    $SessionHost = $OldVM.SessionHost
    if ($OldVM.Instance) {
        throw "More than 1 VM found in Azure with same session host name '$($OldVM.SessionHostName)' (This is not supported):`n$($OldVMInstance | Out-String)`n$($OldVM.Instance | Out-String)"
    }

    $OldVM.Instance = $VMInstance

    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Session host '$($VM.SessionHostName)' with power state: $($VMInstance.PowerState), status: $($SessionHost.Status), update state: $($SessionHost.UpdateState), sessions: $($SessionHost.Session)"}

    if ($VMInstance.PowerState -eq 'VM running') {
        ++$nRunningVMs
    }
}

foreach ($OldVM in $OldVMs.Values) {
    $SessionHost = $OldVM.SessionHost
    $SessionHostName = $OldVM.SessionHostName
    # First Enable Drain Mode for each old VM
    if ($SessionHost.AllowNewSession) {
        Update-AzWvdSessionHost -Name $SessionHostName -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -AllowNewSession:$False | Out-Null
    }
    If ($OldVM.Instance.PowerState -ne 'VM running') {
        
    }

}


# Evaluate Session Hosts for applicability
foreach ($SessionHost in $ListOfSessionHosts) {
    $SessionHostName = $SessionHost.Name.Split("/")[1]
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Analyzing $SessionHostName." }
    $VMName = $SessionHostName.split('.')[0]
    $VMInstance = Get-AzVM -Status -Name $VMName
    # Check if VM has new Image or old image based on ImageVersion tag Value
    if ($VMInstance.Tags.ImageVersion -eq $TargetImageVersion) {
            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$VMName is already using correct image version, skipping this VM." }
    } else {
        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "$VMName is not using correct image version." }
        if ($SessionHost.AllowNewSession) {
            Update-AzWvdSessionHost -Name $SessionHostName -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -AllowNewSession:$False | Out-Null
        }      
        if ($SessionHostName.ToLower().Contains($VMInstance.Name.ToLower())) {
            # Check if the Azure vm is running       
            if ($VMInstance.PowerState -eq "VM running") {
                # VM is running. Add it to list of running hosts.
                $RunningOldHosts += $SessionHost
            } else {
                # VM is not running
                # Delete VM if option specified and the deadline has passed.
                if ($DeleteVM -eq $True -and $DeadlinePassed -eq $true) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The stopped VM: $VMName is being removed from hostpool and deleted." }
                    Get-AzVM -Name $VMName | Remove-AzVirtualMachine
                    Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                }
            }
        }
    }
}

$NumberOfRunningHosts = $RunningOldHosts.Count
if ($NumberofRunningHosts -gt 0)
{
    $SessionHost = $null
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Current number of running hosts that need to be stopped: $NumberOfRunningHosts" }
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Now processing the old Running hosts." }

    foreach ($SessionHost in $RunningOldHosts) {
        $SessionHostName = $SessionHost.Name.Split("/")[1]
        $VMName = $SessionHostName.split('.')[0]
        $VMInstance = Get-AzVM -Status -Name $VMName
        if ($SessionHostName.ToLower().Contains($VMInstance.Name.ToLower())) {
  
            $UserSessions = Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostPoolRGName -SessionHostName $SessionHostName
            $ExistingSessions = $UserSessions.Count
            if ($ExistingSessions -gt 0) {
                Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are $ExistingSessions user sessions on $SessionHostName."}
                foreach ($Session in $UserSessions) {
                    $SplitSessionID = $Session.Id.Split("/")
                    $SessionID = $SplitSessionID[$SplitSessionID.Count-1]
                    write-output "User $($Session.ActiveDirectoryUserName) has Session ID: $SessionID"
                    if ($DeadlinePassed) {
                        Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Logging off all users because deadline has passed." }
                        try {
                            Remove-AzWvdUserSession -ResourceGroupName $HostPoolRGName -HostPoolName $HostpoolName -SessionHostName $SessionHostName -Id $SessionId -Force -ErrorAction Stop
                            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Forcibly logged off the user: $($Session.ActiveDirectoryUserName | Out-String)" }
                            $ExistingSessions = $ExistingSessions - 1
                        }
                        catch {
                            Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Failed to log off user with error: $($_.exception.message)" }
                        }
                    } else {
                        if ($Session.SessionState -eq "Active") {
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
            } else {
                if ($DeleteVM -eq $True -and $DeadlinePassed -eq $true) {
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The stopped VM: $VMName is being removed from hostpool and deleted." }
                    Get-AzVM -Name $VMName | Remove-AzVirtualMachine
                    Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                } else {
                    # Shutdown the Azure VM
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are no user sessions on $SessionHostName."}
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Stopping Azure VM: $VMName and waiting for it to complete ..." }
                    Stop-SessionHost @LAInputObject -VMName $VMName
                }
            }
            
            if ($ExistingSessions -eq 0) {
                if ($DeleteVM -eq $True -and $DeadlinePassed -eq $true) {
                    Start-Sleep -Seconds 10
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "The `"DeleteVM`" option is specified. The stopped VM: $VMName is being removed from hostpool and deleted." }
                    Get-AzVM | Where-Object { $_.Name.Contains($VMName) } | Remove-AzVirtualMachine
                    Remove-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolRGName -Name $SessionHostName
                } else {
                    # Shutdown the Azure VM after 10 seconds
                    Start-Sleep -Seconds 10
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "There are no remaining user sessions on $SessionHostName."}
                    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "Stopping Azure VM: $VMName and waiting for it to complete ..." }
                    Stop-SessionHost @LAInputObject -VMName $VMName
                }
            }
        }    
    }
} else {
    Add-LogEntry @LAInputObject -LogMessageObj @{ hostpool = $HostpoolName; msg = "No remaining Old Hosts Need to be stopped. Exiting Script." }
}