function Remove-PastaVazia {
    <#
    .SYNOPSIS
    Apaga uma pasta só quando ela está vazia.

    .DESCRIPTION
    Uma pasta com arquivos, ou que não existe, fica como está.

    .PARAMETER Pasta
    A pasta que pode ser apagada.

    .EXAMPLE
    Remove-PastaVazia -Pasta 'C:\Tools\WinPlaybook'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Pasta
    )

    $estaVazia = (Test-Path -LiteralPath $Pasta) -and -not (Get-ChildItem -LiteralPath $Pasta -Force | Select-Object -First 1)
    if ($estaVazia) {
        Remove-Item -LiteralPath $Pasta
    }
}
