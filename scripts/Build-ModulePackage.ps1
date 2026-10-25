#Requires -Version 7.4
<#
.SYNOPSIS
Prepares the module folder that gets published: a copy of module/WinPlaybook with
the shim.exe and the version.

.DESCRIPTION
The repository keeps ModuleVersion at 0.0.0: the module-v* tag is the source of the
version, so it is written only in the copy. Returns the path of the copy.
Used by the module release and by the installer tests.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [version] $Version,
    [Parameter(Mandatory)] [string] $Destination
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $Destination 'WinPlaybook'
if (Test-Path -LiteralPath $modulePath) {
    throw "The folder $modulePath already exists."
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../module/WinPlaybook') -Destination $modulePath -Recurse
& (Join-Path $PSScriptRoot 'Save-Shim.ps1') -Destination (Join-Path $modulePath 'bin')

$manifestPath = Join-Path $modulePath 'WinPlaybook.psd1'
$manifest = Get-Content -LiteralPath $manifestPath -Raw
$versionPattern = "(ModuleVersion\s*=\s*)'0\.0\.0'"
if ($manifest -notmatch $versionPattern) {
    throw "WinPlaybook.psd1 must have ModuleVersion = '0.0.0'; the package gets the version from -Version."
}

$manifest -replace $versionPattern, "`${1}'$Version'" | Set-Content -LiteralPath $manifestPath -NoNewline
Test-ModuleManifest -Path $manifestPath | Out-Null

$modulePath
