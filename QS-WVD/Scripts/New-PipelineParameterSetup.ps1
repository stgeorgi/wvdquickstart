<#
.SYNOPSIS
Generate the deployment parameter files required by the WVD deployment using the provided values

.DESCRIPTION
The files are generated from the templates in the "templateFolderPath".
Every value defined as [KeyWord] is replaced with a token of the .psd1 file store in the "parameterSourcePath"
The resulting files are stored in the given path with the same name as the templates, but without the ".template" in their name

.PARAMETER templateFolderPath
The path to the templates folder
Can contain any time of file with '[keyword]' tokens

.PARAMETER parameterSourcePath
The path to the file containing the values for the given keywords (must be a .psd1 file)

.PARAMETER targetFolderPath
The folder to store the resulting parameter files in.

.PARAMETER templateSeachPattern
The pattern to select the desired template files with. Default is "*"

.PARAMETER Confirm
Will promt user to confirm the action to create invasible commands

.PARAMETER WhatIf
Dry run of the script

.EXAMPLE
New-WVDPreReqPipelineParameterSetup -targetFolderPath 'C:\dev\ip\WVD-Automation\WVDPreReq\bin'

Generates the requried tokenized parameter files in path 'C:\dev\ip\WVD-Automation\WVDPreReq\bin'

.EXAMPLE
New-WVDPreReqPipelineParameterSetup -targetFolderPath 'C:\dev\ip\WVD-Automation\WVDPreReq\bin' -templateSeachPattern "wvd*"

Generates the requried tokenized parameter files matching the file pattern 'wvd*' in path 'C:\dev\ip\WVD-Automation\WVDPreReq\bin'
#>
function New-PipelineParameterSetup {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [string] $templateFolderPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "static\templates\pipelineInput"),

        [Parameter(Mandatory = $false)]
        [string] $parameterSourcePath = (Join-Path (Split-Path $PSScriptRoot -Parent) "static\appliedParameters.psd1"),

        [Parameter(Mandatory = $false)]
        [string] $targetFolderPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "Parameters"),

        [Parameter(Mandatory = $false)]
        [string] $templateSeachPattern = "*"
    )

    Write-Verbose "Load parameters file from '$parameterSourcePath'"
    $parametersObject = Import-PowerShellDataFile -Path $parameterSourcePath

    Write-Verbose "Load templates from '$templateFolderPath'"
    $templatePaths = Get-ChildItem "$templateFolderPath\*" -Include $templateSeachPattern | ForEach-Object { $_.FullName }
    foreach ($templatePath in $templatePaths) {

        Write-Verbose "Load template from '$templatePath'"
        $content = Get-Content -Path $templatePath

        Write-Verbose "Replace tokens"
        foreach ($key in $parametersObject.Keys) {
            if ($parametersObject[$key] -is [string]) {
                $content = $content.Replace("[$key]", $parametersObject[$key])
            } elseif ($parametersObject[$key] -is [bool]) {
                 # Required for e.g. bool
                $content = $content.Replace(('"[{0}]"' -f $key), $parametersObject[$key].ToString().ToLower())
            }
            else {
                # Required for e.g. integer
                $content = $content.Replace(('"[{0}]"' -f $key), $parametersObject[$key])
            }
        }

        $fileName = (Split-Path -Path $templatePath -Leaf).Replace('.template', '')
        if ($PSCmdlet.ShouldProcess("Parameter file '$fileName' to '$targetFolderPath'", "Store")) {
            $targetPath = Join-Path $targetFolderPath $fileName
            if (-not (Test-Path $targetPath)) {
                Write-Verbose "Generate file '$targetPath'"
                New-Item -ItemType File -Path $targetPath
            }
            Set-Content -Value $content -Path "$targetFolderPath\$fileName" -Force
        }
    }
}