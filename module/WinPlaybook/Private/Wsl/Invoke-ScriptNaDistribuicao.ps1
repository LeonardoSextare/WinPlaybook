function Invoke-ScriptNaDistribuicao {
    <#
    .SYNOPSIS
    Executa um script de shell numa distribuição WSL e devolve o código de saída e a saída dele.

    .DESCRIPTION
    O script roda no sh, como o usuário escolhido, e recebe os argumentos como $1, $2...,
    sem que um shell os interprete. A saída junta o stdout e o stderr, com as mensagens do
    próprio wsl em UTF-8. Devolve um objeto com CodigoDeSaida e Saida.

    .PARAMETER Distribuicao
    A distribuição WSL, como o wsl --list mostra.

    .PARAMETER Script
    O script de shell.

    .PARAMETER Argumentos
    Os argumentos do script.

    .PARAMETER Usuario
    O usuário da distribuição que executa o script, como root.

    .EXAMPLE
    Invoke-ScriptNaDistribuicao -Distribuicao 'WinPlaybook' -Script 'id -un' -Usuario 'root'

    Devolve CodigoDeSaida 0 e Saida root.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Script,
        [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Argumentos = @(),
        [Parameter(Mandatory)] [string] $Usuario
    )

    $argumentosDoWsl = @('--distribution', $Distribuicao, '--user', $Usuario, '--exec', 'sh', '-c', $Script, 'winplaybook') + $Argumentos

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $linhas = @(wsl @argumentosDoWsl 2>&1 | ForEach-Object {
                $ehLinhaDeErro = $_ -is [Management.Automation.ErrorRecord]
                if ($ehLinhaDeErro) {
                    Write-Output $_.Exception.Message
                }
                else {
                    Write-Output "$_"
                }
            })
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }

    return [pscustomobject]@{
        CodigoDeSaida = $LASTEXITCODE
        Saida         = ($linhas -join [Environment]::NewLine).Trim()
    }
}
