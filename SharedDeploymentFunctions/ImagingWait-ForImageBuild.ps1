function Wait-ForImageBuild {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string] $ImageTemplateName
    )

    begin {
        Write-Debug ("[{0} entered]" -f $MyInvocation.MyCommand)
    }

    process {
        do {
            # Step 1: Get Azure Context
            $currentAzureContext = Get-AzContext

            # Step 2: Get instance profile
            $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
            $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
        
            # Step 3: Get access token
            Write-Verbose ("Tenant: {0}" -f $currentAzureContext.Subscription.Name) -Verbose
            $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
            $accessToken = $token.AccessToken
            $managementEp = $currentAzureContext.Environment.ResourceManagerUrl
            $urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.VirtualMachineImages/imageTemplates/{3}?api-version=2020-02-14", $managementEp, $currentAzureContext.Subscription.Id, $ResourceGroupName, $ImageTemplateName)

            # Step 4: Invoke REST API
            $buildStatusResult = Invoke-WebRequest -Method GET -Uri $urlBuildStatus -UseBasicParsing -Headers  @{"Authorization" = ("Bearer " + $accessToken) } -ContentType application/json
        
            # Step 5: Check success
            $content = $buildStatusResult.Content | ConvertFrom-Json
            $Content.properties.lastRunStatus
            if ($Content.properties.lastRunStatus.runState -ne "Running") {
                break
            }
            Write-Verbose "Waiting 5 seconds" -Verbose
            Start-Sleep 5

        } while ($true)

        $Duration = New-TimeSpan -Start $Content.properties.lastRunStatus.startTime -End $Content.properties.lastRunStatus.endTime
    
        Write-Verbose "It took $($Duration.TotalMinutes) minutes to build and distribute the image." -Verbose
    }
    
    end {
        Write-Debug ("[{0} existed]" -f $MyInvocation.MyCommand)
    }
}
