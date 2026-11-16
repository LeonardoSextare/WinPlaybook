#Requires -Version 7.4

<#
.SYNOPSIS
Prepara a pasta do módulo que é publicada: uma cópia de module/WinPlaybook com as funções num .psm1 só e a versão.

.DESCRIPTION
No repositório, cada função fica num arquivo próprio em Private/ e Public/. Na cópia, as
funções vão para o WinPlaybook.psm1, as de Private/ antes das de Public/, e as duas pastas
saem: o PowerShell carrega um arquivo só bem mais rápido que dezenas de arquivos
pequenos, e cada shim .exe carrega o módulo de novo.

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

$pastasDasFuncoes = @('Private', 'Public') | ForEach-Object { Join-Path $caminhoDoModulo $_ }
$arquivosDasFuncoes = foreach ($pasta in $pastasDasFuncoes) {
    Get-ChildItem -LiteralPath $pasta -Filter '*.ps1' -Recurse | Sort-Object -Property FullName
}
$funcoes = $arquivosDasFuncoes | ForEach-Object { (Get-Content -LiteralPath $_.FullName -Raw).TrimEnd() }
$conteudoDoModulo = @('Set-StrictMode -Version 3.0') + $funcoes
Set-Content -LiteralPath (Join-Path $caminhoDoModulo 'WinPlaybook.psm1') -Value ($conteudoDoModulo -join "`r`n`r`n") -Encoding utf8BOM
Remove-Item -LiteralPath $pastasDasFuncoes -Recurse -Force

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
