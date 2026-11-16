function Invoke-LinhaDeComando {
    <#
    .SYNOPSIS
    Executa um programa com uma linha de comando em texto bruto e devolve o código de saída, a saída e os erros.

    .DESCRIPTION
    A linha de comando chega ao programa como está, sem as mudanças que o operador & faz
    nas aspas no Windows PowerShell 5.1. A saída e os erros são lidos como UTF-8. Devolve um
    objeto com CodigoDeSaida, Saida e Erro.

    .PARAMETER Programa
    O caminho do programa.

    .PARAMETER Argumentos
    A linha de comando passada ao programa, como texto.

    .PARAMETER PastaDeTrabalho
    A pasta onde o programa começa. O padrão é a pasta atual.

    .PARAMETER CaminhoDaEntrada
    Um arquivo que o programa recebe na entrada padrão.

    .EXAMPLE
    Invoke-LinhaDeComando -Programa $caminhoDoShim -Argumentos '-i inventory.yml site.yml'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Programa,
        [string] $Argumentos,
        [string] $PastaDeTrabalho,
        [string] $CaminhoDaEntrada
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
        if ($PastaDeTrabalho) {
            $parametros.WorkingDirectory = $PastaDeTrabalho
        }
        if ($CaminhoDaEntrada) {
            $parametros.RedirectStandardInput = $CaminhoDaEntrada
        }

        $processo = Start-Process @parametros

        return [pscustomobject]@{
            CodigoDeSaida = $processo.ExitCode
            Saida         = "$(Get-Content -LiteralPath $caminhoDaSaida -Raw -Encoding UTF8)".Trim()
            Erro          = "$(Get-Content -LiteralPath $caminhoDosErros -Raw -Encoding UTF8)".Trim()
        }
    }
    finally {
        Remove-Item -LiteralPath $caminhoDaSaida, $caminhoDosErros -ErrorAction SilentlyContinue
    }
}

function ConvertTo-LinhaDeComando {
    <#
    .SYNOPSIS
    Junta argumentos numa linha de comando que os programas do Windows separam de volta nos mesmos argumentos.

    .DESCRIPTION
    Um argumento vazio, com espaços ou com aspas fica entre aspas, com as aspas internas e
    as barras invertidas antes delas escapadas.

    .PARAMETER Argumentos
    Os argumentos, na ordem em que o programa os recebe.

    .EXAMPLE
    ConvertTo-LinhaDeComando -Argumentos '-e', '{"a": "b c"}'

    Devolve -e "{\"a\": \"b c\"}".

    .LINK
    https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Argumentos
    )

    $argumentosCitados = foreach ($argumento in $Argumentos) {
        $precisaDeAspas = ($argumento -eq '') -or ($argumento -match '[\s"]')
        if (-not $precisaDeAspas) {
            Write-Output $argumento
            continue
        }

        $argumentoEscapado = $argumento -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1'
        Write-Output "`"$argumentoEscapado`""
    }

    return @($argumentosCitados) -join ' '
}

function Invoke-ScriptDePowerShell {
    <#
    .SYNOPSIS
    Executa um script na sessão atual do PowerShell e devolve o código de saída, a saída e os erros dos programas que ele chama.

    .DESCRIPTION
    Cada argumento chega ao script como um item, sem passar pela separação que o
    PowerShell faz numa linha digitada. As linhas que os programas escrevem no stderr
    ficam em Erro, separadas da saída. Devolve um objeto com CodigoDeSaida, Saida e Erro.

    .PARAMETER Caminho
    O caminho do script.

    .PARAMETER Argumentos
    Os argumentos do script.

    .PARAMETER CaminhoDaEntrada
    Um arquivo cujas linhas o script recebe pelo pipeline, como em Get-Content arquivo | script.

    .EXAMPLE
    Invoke-ScriptDePowerShell -Caminho (Join-Path $pastaDosShims 'ansible-playbook.ps1') -Argumentos 'site.yml'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Caminho,
        [AllowEmptyString()] [string[]] $Argumentos = @(),
        [string] $CaminhoDaEntrada
    )

    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    if ($CaminhoDaEntrada) {
        $registros = @(Get-Content -LiteralPath $CaminhoDaEntrada -Encoding UTF8 | & $Caminho @Argumentos 2>&1)
    }
    else {
        $registros = @(& $Caminho @Argumentos 2>&1)
    }
    $codigoDeSaida = $LASTEXITCODE

    $linhasDaSaida = $registros | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }
    $linhasDosErros = $registros | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | ForEach-Object { $_.Exception.Message }
    return [pscustomobject]@{
        CodigoDeSaida = $codigoDeSaida
        Saida         = (@($linhasDaSaida) -join "`n").Trim()
        Erro          = (@($linhasDosErros) -join "`n").Trim()
    }
}
