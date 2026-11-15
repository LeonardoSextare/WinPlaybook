function Remove-PastaDosShims {
    <#
    .SYNOPSIS
    Apaga uma pasta de shims, a pasta WinPlaybook dela quando fica vazia e a entrada dela no Path do usuário.

    .PARAMETER Pasta
    A pasta dos shims, como C:\Tools\WinPlaybook\bin.

    .EXAMPLE
    Remove-PastaDosShims -Pasta 'C:\Tools\WinPlaybook\bin'

    Apaga C:\Tools\WinPlaybook e mantém C:\Tools.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Pasta
    )

    Remove-Item -LiteralPath $Pasta -Recurse -Force -ErrorAction SilentlyContinue
    Remove-PastaVazia -Pasta (Split-Path -Path $Pasta -Parent)
    Remove-EntradaDoPathDoUsuario -Pasta $Pasta
}
