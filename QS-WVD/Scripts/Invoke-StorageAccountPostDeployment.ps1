<#
.SYNOPSIS
Run the Post-Deployment for the storage account deployment

.DESCRIPTION
Run the Post-Deployment for the storage account deployment
- Upload required data to the storage account

.PARAMETER orchestrationFunctionsPath
Mandatory. Path to the required functions

.PARAMETER storageAccountName
Mandatory. Name of the storage account to host the deployment files

.PARAMETER Confirm
Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Dry run of the script

.EXAMPLE
Invoke-StorageAccountPostDeployment -orchestrationFunctionsPath $currentDir -storageAccountName "wvdStorageAccount"

Upload any required data to the storage account
#>
function Invoke-StorageAccountPostDeployment {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $orchestrationFunctionsPath,

        [Parameter(Mandatory = $true)]
        [string] $wvdUploadsPath,

        [Parameter(Mandatory = $true)]
        [string] $storageAccountName
    )

    begin {
        Write-Verbose ("[{0} entered]" -f $MyInvocation.MyCommand)
        . "$orchestrationFunctionsPath\Storage\Import-WVDSoftware.ps1"
        . "$orchestrationFunctionsPath\Storage\Compress-WVDCSEContent.ps1"
        . "$orchestrationFunctionsPath\Storage\Export-WVDCSEContentToBlob.ps1"
    }

    process {

        Write-Verbose "###########################################"
        Write-Verbose "## 1 - Download software from public url ##"
        Write-Verbose "###########################################"

        Write-Verbose("#####################")
        Write-Verbose("## 1.1 - LOAD DATA ##")
        Write-Verbose("#####################")
        $ConfigurationFilePath = (Join-Path "$wvdUploadsPath/WVDScripts" "downloads.parameters.json")
        $ConfigurationJson = Get-Content -Path $ConfigurationFilePath -Raw -ErrorAction 'Stop'

        try { $Downloads = $ConfigurationJson | ConvertFrom-Json -ErrorAction 'Stop' }
        catch {
            Write-Error "Configuration JSON content could not be converted to a PowerShell object" -ErrorAction 'Stop'
        }

        Write-Verbose("####################")
        Write-Verbose("## 1.2 - EVALUATE ##")
        Write-Verbose("####################")
        foreach ($download in $Downloads.WVDSoftware) {
            $InputObject = @{
                Url  = $download.Url
                FileName = (Join-Path "$wvdUploadsPath/WVDScripts" $download.DestinationFilePath)
            }
            Write-Verbose $InputObject

            if ($PSCmdlet.ShouldProcess("Required executable files to be installed on WVD VMs", "Import")) {
                Import-WVDSoftware @InputObject -Verbose
                Write-Verbose "WVD Software download invocation finished"
            }
        }
        Write-Verbose "######################################################################################################"
        Write-Verbose "## 2 - Create zip files for all WVDScripts subfolders and save them to the WVDCSEZipToUpload folder ##"
        Write-Verbose "######################################################################################################"

        $InputObject = @{
            SourceFolderPath  = "$wvdUploadsPath/WVDScripts"
            DestinationFolderPath = "$wvdUploadsPath/WVDCSEZipToUpload"
        }
        if ($PSCmdlet.ShouldProcess("$wvdUploadsPath/WVDScripts subfolders as .zip and store them into $wvdUploadsPath/WVDCSEZipToUpload", "Compress")) {
            Compress-WVDCSEContent @InputObject -Verbose
            Write-Verbose "WVD CSE for VMs compression finished"
        }

        Write-Verbose "###################################"
        Write-Verbose "## 3 - Upload to storage account ##"
        Write-Verbose "###################################"

        $InputObject = @{
            ResourceGroupName  = (Get-AzResource -Name $storageAccountName -ResourceType 'Microsoft.Storage/storageAccounts').ResourceGroupName
            StorageAccountName = $storageAccountName
        }
        if ($PSCmdlet.ShouldProcess("Required storage content for storage account '$storageAccountName'", "Export")) {
            Export-WVDCSEContentToBlob @InputObject -Verbose
            Write-Verbose "Storage account content upload invocation finished"
        }

    }
    end {
        Write-Verbose ("[{0} existed]" -f $MyInvocation.MyCommand)
    }
}