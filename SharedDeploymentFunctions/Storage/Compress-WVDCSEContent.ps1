<#
.SYNOPSIS
Compress Scripts and Executable files needed to customize WVD VMs to a zip archive.

.DESCRIPTION
This cmdlet performs compression for all content of each subfolder of a specified source folder into a specified destination folder.

.PARAMETER SourceFolderPath
Specifies the location containing subfolders to be compressed.

.PARAMETER DestinationFolderPath
Specifies the location for the .zip files.

.PARAMETER CompressionLevel
Specifies how much compression to apply when creating the archive file. Fastest as default.

.PARAMETER Confirm
Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Dry run of the script

.EXAMPLE
    Compress-WVDCSEContent -SourceFolderPath "\\path\to\sourcefolder" -DestinationFolderPath "\\path\to\destinationfolder"

    Creates the "\\path\to\destinationfolder" if not existing
    Moves there the scriptExtensionMasterInstaller.ps1 master script for CSE
    For each subfolder in "\\path\to\sourcefolder" creates an archive with the fastest compression level named "subfolder.zip" in the "\\path\to\destinationfolder".
#>

function Compress-WVDCSEContent {

    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the location containing subfolders to be compressed."
        )]
        [string] $SourceFolderPath,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specifies the location for the .zip files."
        )]
        [string] $DestinationFolderPath,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specifies how much compression to apply when creating the archive file. Fastest as default."
        )]
        [string] $CompressionLevel = "Fastest"
    )

    
    Write-Verbose "## Checking destination folder existance $DestinationFolderPath"
    If (!(Test-path $DestinationFolderPath)) {
        Write-Verbose "Not existing, creating..."
        New-Item -ItemType "directory" -Path $DestinationFolderPath
    }

    Write-Verbose "## Move master script from $SourceFolderPath to $DestinationFolderPath"
    $CSEMasterScriptSource = Join-Path $SourceFolderPath "scriptExtensionMasterInstaller.ps1"
    $CSEMasterScriptDestination = Join-Path $DestinationFolderPath "scriptExtensionMasterInstaller.ps1"
    Move-Item -Path $CSEMasterScriptSource -Destination $CSEMasterScriptDestination

    Write-Verbose "## Create archives "
    $subfolders = Get-ChildItem $SourceFolderPath | ?{$_.PSISContainer}
    foreach ($sf in $subfolders){
        try {
            $destinationFilePath = Join-Path -Path $DestinationFolderPath -ChildPath ($sf.Name + ".zip")
            $sourceFilePath = Join-Path -Path $sf.FullName -ChildPath "*"

            Write-Verbose "Working on subfolder $sf"
            Write-Verbose "Archive will be created from path $sourceFilePath"
            Write-Verbose "Archive will be stored as $destinationFilePath"
            
            $CompressInputObject = @{
                Path = $sourceFilePath
                DestinationPath = $destinationFilePath
                CompressionLevel = $CompressionLevel   
                Force = $true 
            }
     
            Write-Verbose "Starting compression...."
            if ($PSCmdlet.ShouldProcess("Required files from $sourceFilePath to $destinationFilePath", "Compress")) {
                Compress-Archive @CompressInputObject
            }
            Write-Verbose "Compression completed."
        }
        catch {
            Write-Error "Compression FAILED: $_"
        } 

    }

}