#Requires -Version 7.4
<#
.SYNOPSIS
Downloads the shim.exe pinned in module/shim.psd1 into the module folder.

.DESCRIPTION
The download is checked against the pinned SHA-256 before anything is extracted.
Used by the development setup and, later, by the module release.
#>
[CmdletBinding()]
param(
    [string] $Destination = (Join-Path $PSScriptRoot '../module/WinPlaybook/bin')
)

$ErrorActionPreference = 'Stop'

$pinnedRelease = Import-PowerShellDataFile (Join-Path $PSScriptRoot '../module/shim.psd1')
$url = "https://github.com/ScoopInstaller/Shim/releases/download/$($pinnedRelease.Implementation)/v$($pinnedRelease.Version)/shim-x64.zip"

$tempFolder = [IO.Directory]::CreateTempSubdirectory('winplaybook-shim-').FullName
try {
    $zipPath = Join-Path $tempFolder 'shim-x64.zip'
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
    $isPinnedZip = $actualHash -eq $pinnedRelease.Sha256
    if (-not $isPinnedZip) {
        throw "The SHA-256 of $url is $actualHash, but module/shim.psd1 pins $($pinnedRelease.Sha256)."
    }

    $extractFolder = Join-Path $tempFolder 'extracted'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractFolder
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $extractFolder 'shim.exe') -Destination $Destination -Force
}
finally {
    Remove-Item -LiteralPath $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
