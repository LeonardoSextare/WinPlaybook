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

function Get-SobraDeComandoInterrompido {
    <#
    .SYNOPSIS
    Interrompe um comando do Ansible no meio, matando o processo do Windows que o chamou, e devolve quantos processos dele continuam na distribuição.

    .DESCRIPTION
    Abre outro PowerShell, da mesma edição, com a entrada e a saída redirecionadas, como a
    extensão do VS Code abre os comandos. Ele importa o módulo e executa um ansible com uma
    tarefa longa, marcada com um texto único. Quando a tarefa aparece na distribuição, a
    árvore de processos do Windows é encerrada. Devolve um objeto com ComecouNaDistribuicao, se a
    tarefa chegou a rodar, e ProcessosQueSobraram, o número de processos com a marca que
    continuam na distribuição depois de 15 segundos. A configuração do WinPlaybook vem do
    $env:LOCALAPPDATA atual.

    .PARAMETER CaminhoDoModulo
    O caminho do manifesto do módulo WinPlaybook.

    .PARAMETER Distribuicao
    A distribuição WSL em que o comando roda.

    .PARAMETER PastaDeTrabalho
    A pasta de onde o comando é chamado.

    .EXAMPLE
    $resultado = Get-SobraDeComandoInterrompido -CaminhoDoModulo $caminhoDoModulo -Distribuicao 'WinPlaybookE2E' -PastaDeTrabalho $TestDrive
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $CaminhoDoModulo,
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $PastaDeTrabalho
    )

    $marca = "winplaybook$([guid]::NewGuid().ToString('N'))"
    $padraoDaMarca = "[$($marca[0])]$($marca.Substring(1))"
    $script = "Import-Module '$CaminhoDoModulo'; Invoke-WinPlaybook ansible localhost -m ansible.builtin.shell -a 'sleep 120; echo $marca'"
    $padraoDaTarefa = "^/bin/sh -c sleep 120; echo $marca`$"
    $contagemDaTarefa = ConvertTo-LinhaDeComando -Argumentos '--distribution', $Distribuicao, '--exec', 'pgrep', '-c', '-f', $padraoDaTarefa
    $contagem = ConvertTo-LinhaDeComando -Argumentos '--distribution', $Distribuicao, '--exec', 'pgrep', '-c', '-f', $padraoDaMarca

    $informacoes = New-Object System.Diagnostics.ProcessStartInfo
    $informacoes.FileName = (Get-Process -Id $PID).Path
    $informacoes.Arguments = ConvertTo-LinhaDeComando -Argumentos '-NoProfile', '-Command', $script
    $informacoes.WorkingDirectory = $PastaDeTrabalho
    $informacoes.UseShellExecute = $false
    $informacoes.CreateNoWindow = $true
    $informacoes.RedirectStandardInput = $true
    $informacoes.RedirectStandardOutput = $true
    $informacoes.RedirectStandardError = $true
    $processo = [System.Diagnostics.Process]::Start($informacoes)
    try {
        $limite = (Get-Date).AddSeconds(60)
        do {
            Start-Sleep -Milliseconds 500
            $emExecucao = [int] (Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos $contagemDaTarefa).Saida
        } while ($emExecucao -eq 0 -and (Get-Date) -lt $limite -and -not $processo.HasExited)
    }
    finally {
        $null = & taskkill.exe /T /F /PID $processo.Id 2>&1
    }

    $limite = (Get-Date).AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 500
        $sobra = [int] (Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos $contagem).Saida
    } while ($sobra -gt 0 -and (Get-Date) -lt $limite)

    $null = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos '--distribution', $Distribuicao, '--user', 'root', '--exec', 'pkill', '-f', $padraoDaMarca)
    return [pscustomobject]@{
        ComecouNaDistribuicao = $emExecucao -gt 0
        ProcessosQueSobraram  = $sobra
    }
}

function Start-VigiaDeTesteTravado {
    <#
    .SYNOPSIS
    Abre um processo que encerra os processos filhos dos testes quando um teste passa do limite de tempo.

    .DESCRIPTION
    O vigia acompanha um arquivo que o Update-VigiaDeTesteTravado renova no começo de cada
    teste. Quando o arquivo fica mais velho que o limite, o vigia encerra todos os processos
    que descendem deste PowerShell, como o wsl.exe e os shims, e o teste preso falha com o
    nome dele, em vez de travar a bateria inteira. O vigia termina junto com este PowerShell.
    Devolve um objeto com o Processo do vigia e o Arquivo que ele acompanha.

    .PARAMETER Segundos
    O tempo máximo de um teste.

    .EXAMPLE
    $vigia = Start-VigiaDeTesteTravado -Segundos 300
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [int] $Segundos = 300
    )

    $arquivo = (New-TemporaryFile).FullName
    $caminhoDoScript = Join-Path ([IO.Path]::GetTempPath()) "vigia-de-teste-travado-$([guid]::NewGuid().ToString('N')).ps1"
    $script = @"
`$idDoPai = $PID
`$arquivo = '$arquivo'
while (Get-Process -Id `$idDoPai -ErrorAction SilentlyContinue) {
    `$idade = ((Get-Date) - (Get-Item -LiteralPath `$arquivo).LastWriteTime).TotalSeconds
    if (`$idade -gt $Segundos) {
        `$processos = @(Get-CimInstance -ClassName Win32_Process)
        `$pais = @(`$idDoPai)
        `$descendentes = @()
        while (`$pais.Count -gt 0) {
            `$filhos = @(`$processos | Where-Object { `$pais -contains `$_.ParentProcessId -and `$_.CommandLine -notlike '*vigia-de-teste-travado-*' })
            `$descendentes += `$filhos
            `$pais = @(`$filhos | ForEach-Object { `$_.ProcessId })
        }
        `$descendentes | ForEach-Object { Stop-Process -Id `$_.ProcessId -Force -ErrorAction SilentlyContinue }
        (Get-Item -LiteralPath `$arquivo).LastWriteTime = Get-Date
    }
    Start-Sleep -Seconds 2
}
Remove-Item -LiteralPath `$arquivo, '$caminhoDoScript' -Force -ErrorAction SilentlyContinue
"@
    [IO.File]::WriteAllText($caminhoDoScript, $script)
    $processo = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', "`"$caminhoDoScript`"" -WindowStyle Hidden -PassThru
    return [pscustomobject]@{
        Processo = $processo
        Arquivo  = $arquivo
        Script   = $caminhoDoScript
    }
}

function Update-VigiaDeTesteTravado {
    <#
    .SYNOPSIS
    Avisa ao vigia que um teste novo começou, e o limite de tempo conta de novo.

    .PARAMETER Vigia
    O objeto que o Start-VigiaDeTesteTravado devolveu.

    .EXAMPLE
    Update-VigiaDeTesteTravado -Vigia $vigia
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [pscustomobject] $Vigia
    )

    (Get-Item -LiteralPath $Vigia.Arquivo).LastWriteTime = Get-Date
}

function Stop-VigiaDeTesteTravado {
    <#
    .SYNOPSIS
    Encerra o vigia e apaga o arquivo que ele acompanha.

    .PARAMETER Vigia
    O objeto que o Start-VigiaDeTesteTravado devolveu.

    .EXAMPLE
    Stop-VigiaDeTesteTravado -Vigia $vigia
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [pscustomobject] $Vigia
    )

    Stop-Process -Id $Vigia.Processo.Id -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Vigia.Arquivo, $Vigia.Script -Force -ErrorAction SilentlyContinue
}
