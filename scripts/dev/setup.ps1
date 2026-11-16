#Requires -Version 7.4

<#
.SYNOPSIS
Confere os requisitos e instala as dependências do desenvolvimento local.

.DESCRIPTION
Confere o WSL, o uv e o git e instala os módulos do requirements.psd1 para o PowerShell 7
e para o Windows PowerShell 5.1. Para no primeiro passo que falhar, com o motivo e o que
fazer.

.EXAMPLE
./scripts/dev/setup.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$versaoMinimaDoUv = [version] '0.11.14'
$caminhoDosRequisitos = Join-Path $PSScriptRoot '..\..\requirements.psd1'
$pastaDeDocumentos = [Environment]::GetFolderPath('MyDocuments')

function Confirm-Uv {
    <#
    .SYNOPSIS
    Para com um erro quando o uv não está instalado ou é anterior à versão mínima.

    .EXAMPLE
    Confirm-Uv
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $uvEstaInstalado = [bool] (Get-Command -Name 'uv' -ErrorAction SilentlyContinue)
    if (-not $uvEstaInstalado) {
        throw 'O uv não está instalado ou não está no PATH. Instale com: winget install astral-sh.uv'
    }

    $versaoAtual = [version] ((uv --version) -split ' ')[1]
    $estaDesatualizado = $versaoAtual -lt $versaoMinimaDoUv
    if ($estaDesatualizado) {
        throw "O uv $versaoAtual é anterior à versão mínima ($versaoMinimaDoUv). Atualize com: uv self update"
    }
}

function Confirm-Wsl {
    <#
    .SYNOPSIS
    Para com um erro quando o WSL não está instalado.

    .EXAMPLE
    Confirm-Wsl
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $wslEstaDisponivel = [bool] (Get-Command -Name 'wsl' -ErrorAction SilentlyContinue)
    if (-not $wslEstaDisponivel) {
        throw 'O WSL não está disponível. Instale com: wsl --install'
    }

    wsl --status *> $null
    $wslEstaInstalado = $LASTEXITCODE -eq 0
    if (-not $wslEstaInstalado) {
        throw 'O WSL não está instalado. Instale com: wsl --install'
    }
}

function Confirm-Git {
    <#
    .SYNOPSIS
    Para com um erro quando o git não está instalado.

    .EXAMPLE
    Confirm-Git
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $gitEstaInstalado = [bool] (Get-Command -Name 'git' -ErrorAction SilentlyContinue)
    if (-not $gitEstaInstalado) {
        throw 'O git não está instalado ou não está no PATH. Instale com: winget install Git.Git'
    }
}

function Install-Requisito {
    <#
    .SYNOPSIS
    Salva os módulos do requirements.psd1 numa pasta de módulos do PowerShell, dentro de Documentos.

    .PARAMETER PastaDosModulos
    A pasta dentro de Documentos, como PowerShell\Modules.

    .EXAMPLE
    Install-Requisito -PastaDosModulos 'PowerShell\Modules'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $PastaDosModulos
    )

    $Path = Join-Path -Path $pastaDeDocumentos -ChildPath $PastaDosModulos
    $requisitos = Import-PowerShellDataFile -LiteralPath $caminhoDosRequisitos
    foreach ($nome in $requisitos.Keys) {
        $requisito = $requisitos[$nome]
        Save-PSResource -Name $nome -Version $requisito.versao -Repository $requisito.repositorio -Path $Path -TrustRepository -Quiet
    }
}

Write-Host (('=' * 60) + "`n" + (' ' * 11) + 'Preparação do ambiente do WinPlaybook' + "`n" + ('=' * 60)) -ForegroundColor DarkYellow

$passos = @(
    @{ Nome = 'Conferindo o WSL'; Acao = { Confirm-Wsl } }
    @{ Nome = 'Conferindo o uv'; Acao = { Confirm-Uv } }
    @{ Nome = 'Conferindo o git'; Acao = { Confirm-Git } }
    @{ Nome = 'Instalando as dependências do PowerShell 7'; Acao = { Install-Requisito -PastaDosModulos 'PowerShell\Modules' } }
    @{ Nome = 'Instalando as dependências do Windows PowerShell'; Acao = { Install-Requisito -PastaDosModulos 'WindowsPowerShell\Modules' } }
)

for ($indice = 0; $indice -lt $passos.Count; $indice++) {
    $passo = $passos[$indice]
    $numeroDoPasso = $indice + 1
    Write-Host "[$numeroDoPasso/$($passos.Count)]" -ForegroundColor DarkCyan -NoNewline
    Write-Host " $($passo.Nome)..." -NoNewline

    try {
        & $passo.Acao
        Write-Host ' OK' -ForegroundColor Green
    }
    catch {
        Write-Host ' ERRO' -ForegroundColor Red
        Write-Host "O passo $numeroDoPasso falhou: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nAmbiente pronto!" -ForegroundColor Green
