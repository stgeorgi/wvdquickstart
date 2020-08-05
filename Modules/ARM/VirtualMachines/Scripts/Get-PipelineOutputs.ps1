param (
  [Parameter(Mandatory = $true)]
  [string]
  $outputString
)

Write-Host "ARM output JSON is:"
Write-Host $outputString

$outputObj = $outputString | ConvertFrom-Json

$outputObj.PSObject.Properties | ForEach-Object {
  $type = ($_.value.type).ToLower()
  $keyname = "$($_.name)"
  $value = $_.value.value

  if ($type -eq "securestring") {
    Write-Host "##vso[task.setvariable variable=$keyname;issecret=true]$value"
    Write-Host "Added Azure DevOps secret variable '$keyname' ('$type')"
  }
  elseif ($type -eq "string") {
    Write-Host "##vso[task.setvariable variable=$keyname]$value"
    Write-Host "Added Azure DevOps variable '$keyname' ('$type') with value '$value'"
  }
  elseif ($type -eq "array") {
    for ($i = 0; $i -lt $value.Length; $i++) {
      $variable = "$keyname" + "$i"
      $arrayValue = $value[$i]
      Write-Host "##vso[task.setvariable variable=$variable]$arrayValue"
      Write-Host "Added Azure DevOps variable '$variable' ('$type') with value '$arrayValue'"
    }
  }
  else {
    Throw "Type '$type' is not supported for '$keyname'"
  }
}