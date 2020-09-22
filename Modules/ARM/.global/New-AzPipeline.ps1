function Create-Pipelines
{
    param (
        [Parameter(Mandatory, HelpMessage = "Azure DevOps Organization: <OrganizationName>")][string]$OrganizationName,
        [Parameter(Mandatory, HelpMessage = "Azure DevOps Project: <ProjectName>")][string]$ProjectName,
        [Parameter(Mandatory, HelpMessage = "Azure DevOps Repository: RepositoryName>")][string]$RepositoryName,
        [Parameter(HelpMessage = "Example: Pipelines")][string]$FolderPath = "Pipelines",
        [Parameter(HelpMessage = "Example: 2020-04-11 or 2020-05-*")][string]$Version,
        [Parameter(HelpMessage = "Example: C:\Modules\")][string]$PipelinePath = ".",
        [Parameter()][switch]$Latest,
        [Parameter()][switch]$All
    )
    $AzContext = Get-AzContext
    if (!$AzContext)
    {
        Write-Output "No Azure context found - Please make sure to login with the help of Connect-AzAccount or az login."
        exit
    } 
    $AzurePipelines = Get-ChildItem -Path $PipelinePath -Recurse | Where-Object { $_.Name -like "pipeline.yml" } | Sort-Object FullName
    $PipelinesArray = @()
    $OldPipelinesArray = @()
    foreach ($Pipeline in $azurePipelines)
    {
        $PipeObj = New-Object -TypeName PSCustomObject
        $YmlPath = $Pipeline.fullname.replace("\", "/")
        $PathSplit = $YmlPath.Split("/")
        $YmlPath = $PathSplit[-6] + "/" + $PathSplit[-5] + "/" + $PathSplit[-4] + "/" + $PathSplit[-3] + "/" + $PathSplit[-2] + "/" + $PathSplit[-1]
        $ModuleName = $PathSplit[-4]
        $PipelineName = $PathSplit[-4] + "-" + $PathSplit[-3]
        $PipelineVersion = $PathSplit[-3]
        $PipeObj | Add-Member -MemberType NoteProperty -Name ProjectName -Value $ProjectName
        $PipeObj | Add-Member -MemberType NoteProperty -Name RepositoryName -Value $RepositoryName
        $PipeObj | Add-Member -MemberType NoteProperty -Name FolderPath -Value $FolderPath
        $PipeObj | Add-Member -MemberType NoteProperty -Name YmlPath -Value $YmlPath
        $PipeObj | Add-Member -MemberType NoteProperty -Name ModuleName -Value $ModuleName
        $PipeObj | Add-Member -MemberType NoteProperty -Name PipelineName -Value $PipelineName
        $PipeObj | Add-Member -MemberType NoteProperty -Name PipelineVersion -Value $PipelineVersion
        if ($Version -lt $PipelineVersion)
        {
            $PipelinesArray += $PipeObj
        }
        elseif ($All -and !$Latest)
        {
            $PipelinesArray += $PipeObj
        }
        else
        {
            $OldPipelinesArray += $PipeObj
        }
    }
    if ($PipelinesArray.Count -gt 0)
    {
        Write-Output "$($PipelinesArray.Count) Pipelines have been identified."
    }
    else
    {
        Write-Output "No Pipelines have been identified. Exiting."
        Start-Sleep 1
        exit
    }
    if ($OldPipelinesArray)
    {
        Write-Output "$($OldPipelinesArray.Count) Modules are older than $Version and will be skipped."
    }
    if (!$All -and $Latest)
    {
        $Modules = ($PipelinesArray).ModuleName | Select-Object -Unique
        $LatestModules = @()
        foreach ($Module in $Modules)
        {
            $LatestModules += $PipelinesArray | Where-Object { $_.ModuleName -eq $Module } | Sort-Object PipelineVersion | Select-Object -Last 1
        }
        $PipelinesArray = @()
        $PipelinesArray = $LatestModules
        Write-Output "$($PipelinesArray.Count) Azure Pipelines (latest) will be created."
    }
    if ($Version -ne "")
    {
        Write-Output "$($PipelinesArray.Count) Azure Pipeline(s) prior to $Version version will be created."
    }
    if ($All -and !$Latest)
    {
        $Modules = ($PipelinesArray).ModuleName | Select-Object -Unique
        $LatestModules = @()
        foreach ($Module in $Modules)
        {
            $LatestModules += $PipelinesArray | Where-Object { $_.ModuleName -eq $Module } | Sort-Object PipelineVersion | Select-Object -Last 1
        }
        $PipelinesArray = @()
        $PipelinesArray = $LatestModules
        Write-Output "$($PipelinesArray.Count) Azure Pipelines will be created."
    }

    $PipelinesSkipped = @()
    $PipelinesCreated = @()
    $ExistingPipelines = (az pipelines list --organization ("https://dev.azure.com/" + $OrganizationName) --project $ProjectName | ConvertFrom-Json).name
    foreach ($Pipeline in $PipelinesArray)
    {
        if ($Pipeline.PipelineName -notin $ExistingPipelines)
        {
            Write-Output "Creating Azure Pipeline $($Pipeline.PipelineName) ... "
            $Job = Start-Job -Name $Pipeline.PipelineName -ScriptBlock {
                param($Pipeline)
                # $ErrorActionPreference = Stop
                az pipelines create --project "$($Pipeline.ProjectName)" `
                    --repository "$($Pipeline.RepositoryName)" `
                    --repository-type tfsgit --branch master `
                    --folder-path "$($Pipeline.FolderPath)" `
                    --name "$($Pipeline.PipelineName)" `
                    --yml-path "$($Pipeline.YmlPath)" `
                    --skip-run
            } -ArgumentList $Pipeline
            $PipelinesCreated += $Pipeline
        }
        else
        {
            Write-Output "Azure Pipeline $($Pipeline.PipelineName) exists already and will be skipped."
            $PipelinesSkipped += $Pipeline
        }
    }
    Write-Host "Please wait " -NoNewline
    while (Get-Job -State Running)
    {
        Start-Sleep 5
        Write-Host ". " -NoNewline
    }
    Write-Output "$($PipelinesCreated.Count) Azure Pipeline(s) have been created!"
    Write-Output "$($PipelinesSkipped.Count) Azure Pipeline(s) have been skipped!"
    $Url = "https://dev.azure.com/" + $OrganizationName + "/" + $adoProject + "/" + "_build?view=folders"
    Write-Output "Please check your Azure  Pipelines here: $Url"
}


$inputObject = @{
    OrganizationName = 'SecInfra' 
    ProjectName      = 'Components'
    RepositoryName   = 'WVD-Automation' 
    FolderPath       = 'Test' 
    PipelinePath     = 'C:\Users\mabara\source\Microsoft\WVD-Automation\WVD-Automation\Implementation\2020-Spring\Modules' 
    Latest           = $true
}

Create-Pipelines @inputObject