function Write-LinhaColoridaNoErro {
    <#
    .SYNOPSIS
    Escreve uma linha no stderr com a cor escolhida e volta à cor anterior do console.

    .DESCRIPTION
    Com a variável NO_COLOR definida, escreve a linha sem cor.

    .PARAMETER Texto
    A linha.

    .PARAMETER Cor
    A cor do texto no console.

    .EXAMPLE
    Write-LinhaColoridaNoErro -Texto 'Há uma versão nova.' -Cor 'Yellow'

    .LINK
    https://no-color.org/
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Texto,
        [Parameter(Mandatory)] [ConsoleColor] $Cor
    )

    $usaCor = -not [bool] $env:NO_COLOR
    if (-not $usaCor) {
        [Console]::Error.WriteLine($Texto)
        return
    }

    $corOriginal = [Console]::ForegroundColor
    try {
        [Console]::ForegroundColor = $Cor
        [Console]::Error.WriteLine($Texto)
    }
    finally {
        [Console]::ForegroundColor = $corOriginal
    }
}
