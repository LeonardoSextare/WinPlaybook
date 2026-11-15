function Invoke-LinhaDeComando {
    <#
    .SYNOPSIS
    Executa um programa com uma linha de comando em texto bruto e devolve o código de saída, a saída e os erros.

    .DESCRIPTION
    A linha de comando chega ao programa como está, sem as mudanças que o operador & faz
    nas aspas no Windows PowerShell 5.1. Devolve um objeto com CodigoDeSaida, Saida e Erro.

    .PARAMETER Programa
    O caminho do programa.

    .PARAMETER Argumentos
    A linha de comando passada ao programa, como texto.

    .EXAMPLE
    Invoke-LinhaDeComando -Programa $caminhoDoShim -Argumentos '-i inventory.yml site.yml'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Programa,
        [string] $Argumentos
    )

    $caminhoDaSaida = (New-TemporaryFile).FullName
    $caminhoDosErros = (New-TemporaryFile).FullName
    try {
        $parametros = @{
            FilePath               = $Programa
            NoNewWindow            = $true
            Wait                   = $true
            PassThru               = $true
            RedirectStandardOutput = $caminhoDaSaida
            RedirectStandardError  = $caminhoDosErros
        }
        if ($Argumentos) {
            $parametros.ArgumentList = $Argumentos
        }

        $processo = Start-Process @parametros

        return [pscustomobject]@{
            CodigoDeSaida = $processo.ExitCode
            Saida         = "$(Get-Content -LiteralPath $caminhoDaSaida -Raw)".Trim()
            Erro          = "$(Get-Content -LiteralPath $caminhoDosErros -Raw)".Trim()
        }
    }
    finally {
        Remove-Item -LiteralPath $caminhoDaSaida, $caminhoDosErros -ErrorAction SilentlyContinue
    }
}
