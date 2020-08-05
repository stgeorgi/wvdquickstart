<#
.SYNOPSIS
Upload Scripts and Executable files needed to customize WVD VMs to the created Storage Accounts blob containers.

.DESCRIPTION
This cmdlet uploads files specifiied in the contentToUpload-sourcePath parameter to the blob specified in the contentToUpload-targetBlob parameter to the specified Azure Storage Account.

.PARAMETER ResourceGroupName
Name of the resource group that contains the Storage account to update.

.PARAMETER StorageAccountName
Name of the Storage account to update.

.PARAMETER contentToUpload
Optional. Array with a contentmap to upload.
E.g. $( @{ sourcePath = 'WVDScripts'; targetBlob = 'wvdscripts' })

.PARAMETER Confirm
Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Dry run of the script

.EXAMPLE
    Export-WVDCSEContentToBlob -ResourceGroupName "RG01" -StorageAccountName "storageaccount01"

    Uploads files contained in the WVDScripts Repo folder and the files contained in the WVDScaling Repo folder
    respectively to the "wvdscripts" blob container and to the "wvdScaling" blob container in the Storage Account "storageaccount01"
    of the Resource Group "RG01"

.EXAMPLE
    Export-WVDCSEContentToBlob -ResourceGroupName "RG01" -StorageAccountName "storageaccount01" -contentToUpload $( @{ sourcePath = 'WVDScripts'; targetBlob = 'wvdscripts' })
    
    Uploads files contained in the WVDScripts Repo folder to the "wvdscripts" blob container in the Storage Account "storageaccount01"
    of the Resource Group "RG01"
#>
function Export-WVDCSEContentToBlob {

    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the name of the resource group that contains the Storage account to update."
        )]
        [string] $ResourceGroupName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the name of the Storage account to update."
        )]
        [string] $StorageAccountName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Map of source/target tuples for upload"
        )]
        [Hashtable[]] $contentToUpload = $(
            @{
                sourcePath = 'WVDCSEZipToUpload'
                targetBlob = 'wvdscripts'
            },
            @{
                sourcePath = 'WVDScaling'
                targetBlob = 'wvdscaling'
            }
        )
    )

    Write-Verbose "Getting storage account context."
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction Stop
    $ctx = $storageAccount.Context

    Write-Verbose "Building paths to the local folders to upload."
    Write-Verbose "Script Directory: '$PSScriptRoot'"
    $sourcesPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $contentDirectory = Join-Path -Path $sourcesPath "parameters/s/Uploads"
    Write-Verbose "Content directory: '$contentDirectory'"

    foreach ($contentObject in $contentToUpload) {

        $sourcePath = $contentObject.sourcePath
        $targetBlob = $contentObject.targetBlob

        try {
            $pathToContentToUpload = Join-Path $contentDirectory $sourcePath
            Write-Verbose "Processing content in path: '$pathToContentToUpload'"
    
            Write-Verbose "Testing local path"
            If (-Not (Test-Path -Path $pathToContentToUpload)) {
                throw "Testing local paths FAILED: Cannot find content path to upload '$pathToContentToUpload'"
            }
            Write-Verbose "Testing paths: SUCCEEDED"
    
            Write-Verbose "Getting files to be uploaded..."
            $scriptsToUpload = Get-ChildItem -Path $pathToContentToUpload -ErrorAction Stop
            Write-Verbose "Files to be uploaded:"
            Write-Verbose ($scriptsToUpload.Name | Format-List | Out-String)

            Write-Verbose "Testing blob container"
            Get-AzStorageContainer -Name $targetBlob -Context $ctx -ErrorAction Stop
            Write-Verbose "Testing blob container SUCCEEDED"
    
            if ($PSCmdlet.ShouldProcess("Files to the '$targetBlob' container", "Upload")) {
                $scriptsToUpload | Set-AzStorageBlobContent -Container $targetBlob -Context $ctx -Force -ErrorAction Stop
            }
        }
        catch {
            Write-Error "Upload FAILED: $_"
        }
    }
}
