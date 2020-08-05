<#
.SYNOPSIS
Upload Scripts and Executable files needed to customize WVD VMs to the created Storage Accounts blob containers.

.DESCRIPTION
This cmdlet uploads files specifiied in the contentToUpload-sourcePath parameter to the blob specified in the contentToUpload-targetBlob parameter to the specified Azure Storage Account.

.PARAMETER Url
Specifies the URI from which to download data.

.PARAMETER FileName
Specifies the name of the local file that is to receive the data.

.PARAMETER Confirm
Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Dry run of the script

.EXAMPLE
    Import-WVDSoftware -Url "https://aka.ms/fslogix_download" -FileName "FSLogixApp.zip"

    Downloads file from the specified Uri and save it to the specified filepath 
#>

function Import-WVDSoftware {

    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the URI from which to download data."
        )]
        [string] $Url,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the name of the local file that is to receive the data."
        )]
        [string] $FileName
    )

    Write-Verbose "Getting current time."
    $start_time = Get-Date

    try { 
        Write-Verbose "Starting download...."
        if ($PSCmdlet.ShouldProcess("Required executable files from $url to $filename", "Import")) {
            (New-Object System.Net.WebClient).DownloadFile($Url, $FileName)
        }
        Write-Verbose "Download completed."
        Write-Verbose "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    }
    catch {
        Write-Error "Download FAILED: $_"
    }
}