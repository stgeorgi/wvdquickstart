function Invoke-GeneralDeployment {

  [CmdletBinding()]
  param(
    [string] $resourcegroupName,
    [string] $location,
    [string] $moduleName,
    [string] $moduleVersion,
    [string] $parameterFilePath,
    [Parameter(Mandatory = $false)][hashtable] $optionalParameters,
    [string] $managementGroupId
  )

  begin {
    Write-Debug ("[{0} entered]" -f $MyInvocation.MyCommand)
  }

  process {

    $templateUri = 'https://raw.githubusercontent.com/samvdjagt/wvdquickstart/master/Modules/ARM/{0}/deploy.json' -f $moduleName

    Write-Verbose "Parameters are" -Verbose
    $param = ConvertFrom-Json (Get-Content -Raw -Path $parameterFilePath)
    $paramSet = @{ }
    $param.parameters | Get-Member -MemberType NoteProperty | ForEach-Object { 
      $key = $_.Name
      $value = $param.parameters.($_.Name).Value
      if ($value -is [string]) {
        $formattedValue = $value.subString(0, [System.Math]::Min(15, $value.Length))
        if ($value.Length -gt 40) {
          $formattedValue += '...'
        }
      }
      else {
        $formattedValue = $value
      }
      $paramSet[$key] = $formattedValue
    }
    Write-Verbose ($paramSet | Format-Table | Out-String) -Verbose

    Write-Verbose "Additional Parameters are"
    Write-Verbose ($optionalParameters | Format-Table | Out-String) -Verbose

    Write-Verbose "Deploy to resource group '$resourcegroupName'"
    $deploymentId = 'WVD-QuickStart-Deployment'

    $DeploymentInputs = @{
      Name                  = ("{0}-{1}" -f $moduleName, $deploymentId)
      TemplateUri           = $templateUri
      TemplateParameterFile = $parameterFilePath
      Verbose               = $true
      ErrorAction           = "Stop"
    }

    Foreach ($key in $optionalParameters.Keys) {
      $DeploymentInputs += @{
        $key = $optionalParameters.Item($key)
      }
    }

    $deploymentSchema = (Invoke-RestMethod -Uri $templateUri -Method 'GET').'$schema' # Works with PS7
    Write-Verbose "Evaluating schema [$deploymentSchema]" -Verbose
    switch -regex ($deploymentSchema) {
      '\/deploymentTemplate.json#$' {
        Write-Verbose 'Handling resource group level deployment' -Verbose
        if (-not (Get-AzResourceGroup -Name $resourcegroupName -ErrorAction SilentlyContinue)) {
          Write-Verbose 'Deploying resource group [$resourcegroupName]' -Verbose
          New-AzResourceGroup -Name $resourcegroupName -Location $location
        }

        if (-not (Get-AzResourceGroup -Name $resourcegroupName -ErrorAction SilentlyContinue)) {
          $Location = $location -replace " ", ""
          New-AzResourceGroup -Name $resourcegroupName -Location $Location
        }

        $Deployment = New-AzResourceGroupDeployment @DeploymentInputs -ResourceGroupName $resourcegroupName
        break
      }
      '\/subscriptionDeploymentTemplate.json#$' {
        Write-Verbose 'Handling subscription level deployment' -Verbose
        $DeploymentInputs += @{
          Location = $location
        }
        $Deployment = New-AzSubscriptionDeployment @DeploymentInputs
        break
      }
      '\/managementGroupDeploymentTemplate.json#$' {
        Write-Verbose 'Handling management group level deployment' -Verbose
        $DeploymentInputs += @{
          ManagementGroupId = $managementGroupId
          Location          = $location
        } 
        $Deployment = New-AzManagementGroupDeployment @DeploymentInputs
        break
      }
      '\/tenantDeploymentTemplate.json#$' {
        Write-Verbose 'Handling tenant level deployment' -Verbose
        $DeploymentInputs += @{
          Location = $location
        }
        $Deployment = New-AzTenantDeployment @DeploymentInputs
        break
      }
      default {
        throw "[$deploymentSchema] is a non-supported ARM template schema"
      }
    }

    if ($Deployment.Outputs) {
      foreach ($Outputkey in $Deployment.Outputs.Keys) {
        Write-Verbose "Set [$Outputkey] deployment output as pipeline environment variable" -Verbose
        Write-Host ("##vso[task.setvariable variable={0};isOutput=true]{1}" -f $Outputkey, $Deployment.Outputs[$Outputkey].Value)
      }
    }

    Write-Verbose "Deployment successful" -Verbose
  }
  end {
    Write-Debug ("[{0} existed]" -f $MyInvocation.MyCommand)
  }
}
