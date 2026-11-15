function Get-CaminhoDoShimEmpacotado {
    <#
    .SYNOPSIS
    Devolve o caminho do shim.exe que o scripts/Save-Shim.ps1 baixa para a pasta do módulo.

    .EXAMPLE
    Get-CaminhoDoShimEmpacotado
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $caminhoDoShim = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../../module/WinPlaybook/bin/shim.exe'))

    $shimFoiBaixado = Test-Path -LiteralPath $caminhoDoShim
    if (-not $shimFoiBaixado) {
        throw "O shim.exe não está em $caminhoDoShim. Rode antes o scripts/Save-Shim.ps1."
    }

    return $caminhoDoShim
}

function New-ShimDeTeste {
    <#
    .SYNOPSIS
    Cria um shim que executa um programa qualquer e devolve o caminho do .exe dele.

    .PARAMETER Pasta
    A pasta onde o .exe e o .shim são criados.

    .PARAMETER Nome
    O nome do shim, sem extensão.

    .PARAMETER CaminhoDoAlvo
    O programa que o shim executa.

    .PARAMETER ArgumentosDoAlvo
    Os argumentos que o shim passa ao programa antes dos que ele recebe.

    .EXAMPLE
    New-ShimDeTeste -Pasta $TestDrive -Nome 'sai-com' -CaminhoDoAlvo $caminhoDoPowerShell -ArgumentosDoAlvo '-NoProfile -Command exit 7'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Pasta,
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $CaminhoDoAlvo,
        [Parameter(Mandatory)] [string] $ArgumentosDoAlvo
    )

    $caminhoDoExe = Join-Path -Path $Pasta -ChildPath "$Nome.exe"
    Copy-Item -LiteralPath (Get-CaminhoDoShimEmpacotado) -Destination $caminhoDoExe
    Set-Content -LiteralPath (Join-Path -Path $Pasta -ChildPath "$Nome.shim") -Value @(
        "path = $CaminhoDoAlvo"
        "args = $ArgumentosDoAlvo"
    )

    return $caminhoDoExe
}
