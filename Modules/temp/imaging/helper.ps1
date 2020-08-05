function Register-AzProviderFeatureAndWait
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $ProviderNamespace,


        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        $FeatureName
    )


    [int]$Timer = 0
    Do
    {
        $RegistrationState = (Get-AzProviderFeature -ProviderNamespace $ProviderNamespace -FeatureName $FeatureName).RegistrationState
        If ($RegistrationState -ne 'Registered' -and $RegistrationState -ne 'Registering')
        {
            Write-Output "Registering `"$FeatureName`" feature in the `"$ProviderNamespace`" Azure Feature Provider Namespace."
            Register-AzProviderFeature -ProviderNamespace $ProviderNamespace -FeatureName $FeatureName
        }
        If ($RegistrationState -eq 'Registering')
        {
            If ($timer -eq 0)
            {
                Write-Output "Azure is currently registering the `"$FeatureName`" feature."
            }
            Else
            {
                [int]$elapsedtime = $timer*10
                Write-Output "`"$FeatureName`" is still being registered after $elapsedtime Seconds."
            }
            Start-Sleep 10
            $Timer = $Timer + 1
        }
        If ($RegistrationState -eq 'Registered')
        {
            Write-Output "The `"$FeatureName`" feature in the `"$ProviderNamespace`" Azure Feature Provider Namespace is registered."
        }
    }
    Until (($RegistrationState -eq 'Registered') -or ($Timer -eq 60))
}

Register-AzProviderFeatureandWait -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview

#############################################
# the resource deployment has to happen here
#############################################

break

# The below has to be run on behalf of a subscription owner!!!

# add logic here that finds the latest image template in the imaging RG

# Invoke build 
$imageTemplateName = "myImage-2020-05-27-20-45-09"
$rgName = "WVD-Imaging-RG"
# Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $rgName -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview" -Action Run -Force
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $rgName -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Action Run -Force

# Check status

$currentAzureContext = Get-AzContext

### Step 2: Get instance profile
$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
    
Write-Verbose ("Tenant: {0}" -f  $currentAzureContext.Subscription.Name)
 
### Step 4: Get token  
$token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
$accessToken=$token.AccessToken
$managementEp = $currentAzureContext.Environment.ResourceManagerUrl

do {
    # $urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.VirtualMachineImages/imageTemplates/{3}?api-version=2019-05-01-preview", $managementEp, $currentAzureContext.Subscription.Id,$rgName,$imageTemplateName)
    $urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.VirtualMachineImages/imageTemplates/{3}?api-version=2020-02-14", $managementEp, $currentAzureContext.Subscription.Id,$rgName,$imageTemplateName)

    $buildStatusResult = Invoke-WebRequest -Method GET  -Uri $urlBuildStatus -UseBasicParsing -Headers  @{"Authorization"= ("Bearer " + $accessToken)} -ContentType application/json 
    
    $content = $buildStatusResult.Content |ConvertFrom-Json
    $Content.properties.lastRunStatus
    if ($Content.properties.lastRunStatus.runState -ne "Running")
    {
        break
    }
    Start-Sleep 5
} while ($true)


# the status is reported Succeeded, while the RG is still being deleted

# add logic to show build time at the end

# add logic to optionally delete the "IT-" RG after the image was built - but only if the image was successfully built 

# implement logic to notify admins that a new major /(minor?) version is available






##############################################
# this is for the ARM template deployment script:
##############################################

do {
    # Step 1: Get Azure Context
    $currentAzureContext = Get-AzContext

    # Step 2: Get instance profile
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
    
    # Step 3: Get access token
    Write-Verbose ("Tenant: {0}" -f $currentAzureContext.Subscription.Name)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
    $accessToken = $token.AccessToken
    $managementEp = $currentAzureContext.Environment.ResourceManagerUrl
    $urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.VirtualMachineImages/imageTemplates/{3}?api-version=2020-02-14", $managementEp, $currentAzureContext.Subscription.Id, $rgName, $imageTemplateName)

    # Step 4: Invoke REST API
    $buildStatusResult = Invoke-WebRequest -Method GET  -Uri $urlBuildStatus -UseBasicParsing -Headers  @{"Authorization" = ("Bearer " + $accessToken) } -ContentType application/json 
    
    # Step 5: Check success
    $content = $buildStatusResult.Content | ConvertFrom-Json
    $Content.properties.lastRunStatus
    if ($Content.properties.lastRunStatus.runState -ne "Running")
    {
        break
    }
    Start-Sleep 5

} while ($true)
