#Requires -Version 7.4

<#
.SYNOPSIS
Prepara a pasta do módulo que é publicada: uma cópia de module/WinPlaybook com o shim.exe e a versão.

.DESCRIPTION
No repositório, o ModuleVersion fica em 0.0.0, e a versão vem da tag v<versão>. Por isso
a versão só é gravada na cópia. Devolve o caminho da cópia.

.PARAMETER Versao
A versão gravada no manifesto da cópia, como 0.3.0.

.PARAMETER PastaDeDestino
A pasta onde a cópia é criada, numa subpasta WinPlaybook que ainda não pode existir.

.EXAMPLE
./scripts/Build-PacoteDoModulo.ps1 -Versao 0.3.0 -PastaDeDestino $env:RUNNER_TEMP

Devolve <RUNNER_TEMP>\WinPlaybook, pronto para o Publish-PSResource.
#>
[CmdletBinding()]
[OutputType([string])]
param(
    [Parameter(Mandatory)] [version] $Versao,
    [Parameter(Mandatory)] [string] $PastaDeDestino
)

$ErrorActionPreference = 'Stop'

$caminhoDoModulo = Join-Path $PastaDeDestino 'WinPlaybook'
$moduloJaExiste = Test-Path -LiteralPath $caminhoDoModulo
if ($moduloJaExiste) {
    throw "A pasta $caminhoDoModulo já existe. Escolha outra -PastaDeDestino, ou apague a pasta."
}

$null = New-Item -ItemType Directory -Path $PastaDeDestino -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../module/WinPlaybook') -Destination $caminhoDoModulo -Recurse
& (Join-Path $PSScriptRoot 'Save-Shim.ps1') -Destination (Join-Path $caminhoDoModulo 'bin')

$caminhoDoManifesto = Join-Path $caminhoDoModulo 'WinPlaybook.psd1'
$manifesto = Get-Content -LiteralPath $caminhoDoManifesto -Raw
$padraoDaVersao = "(ModuleVersion\s*=\s*)'0\.0\.0'"
$temVersaoZerada = $manifesto -match $padraoDaVersao
if (-not $temVersaoZerada) {
    throw "O WinPlaybook.psd1 precisa ter ModuleVersion = '0.0.0'; o pacote recebe a versão pelo -Versao."
}

$manifesto -replace $padraoDaVersao, "`${1}'$Versao'" | Set-Content -LiteralPath $caminhoDoManifesto -NoNewline -Encoding utf8BOM
$null = Test-ModuleManifest -Path $caminhoDoManifesto

return $caminhoDoModulo
