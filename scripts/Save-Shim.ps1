#Requires -Version 7.4

<#
.SYNOPSIS
Baixa o shim.exe fixado no module/shim.psd1 para a pasta do módulo.

.DESCRIPTION
O download é conferido contra o SHA-256 fixado antes de qualquer extração. Um hash
diferente interrompe o script sem tocar na pasta de destino.

.PARAMETER Destination
A pasta que recebe o shim.exe. O padrão é module/WinPlaybook/bin.

.EXAMPLE
./scripts/Save-Shim.ps1

.LINK
https://github.com/ScoopInstaller/Shim
#>
[CmdletBinding()]
param(
    [string] $Destination = (Join-Path $PSScriptRoot '../module/WinPlaybook/bin')
)

$ErrorActionPreference = 'Stop'

$shimFixado = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot '../module/shim.psd1')
$url = "https://github.com/ScoopInstaller/Shim/releases/download/$($shimFixado.Implementacao)/v$($shimFixado.Versao)/shim-x64.zip"

$pastaTemporaria = [IO.Directory]::CreateTempSubdirectory('winplaybook-shim-').FullName
try {
    $caminhoDoZip = Join-Path $pastaTemporaria 'shim-x64.zip'
    Invoke-WebRequest -Uri $url -OutFile $caminhoDoZip

    $hashBaixado = (Get-FileHash -LiteralPath $caminhoDoZip -Algorithm SHA256).Hash
    $ehOZipFixado = $hashBaixado -eq $shimFixado.Sha256
    if (-not $ehOZipFixado) {
        throw "O SHA-256 de $url é $hashBaixado, mas o module/shim.psd1 fixa $($shimFixado.Sha256)."
    }

    $pastaExtraida = Join-Path $pastaTemporaria 'extraido'
    Expand-Archive -LiteralPath $caminhoDoZip -DestinationPath $pastaExtraida
    $null = New-Item -ItemType Directory -Path $Destination -Force
    Copy-Item -LiteralPath (Join-Path $pastaExtraida 'shim.exe') -Destination $Destination -Force
}
finally {
    Remove-Item -LiteralPath $pastaTemporaria -Recurse -Force -ErrorAction SilentlyContinue
}
