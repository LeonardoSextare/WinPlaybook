function Invoke-ComandoNoWsl {
    <#
    .SYNOPSIS
    Executa um comando na distribuição WSL do WinPlaybook, a partir da pasta atual.

    .DESCRIPTION
    O comando roda num login shell, que tem no PATH as pastas do usuário, como
    ~/.local/bin. Os argumentos chegam ao comando sem que um shell os interprete, e os
    caminhos do Windows viram os caminhos deles na distribuição.

    Um comando que não existe na distribuição é recusado com o código de saída 127. Quando a
    distribuição não existe mais, o erro explica como instalá-la de novo.

    A saída do comando chega em UTF-8, então os acentos ficam certos também quando o
    PowerShell a captura, como em $saida = ansible-playbook site.yml.

    As variáveis de ambiente ANSIBLE_ do Windows chegam ao comando, com os caminhos do
    Windows convertidos. As outras variáveis chegam quando estão no WSLENV, como o WSL faz.

    .PARAMETER Comando
    O comando na distribuição, como ansible-playbook.

    .PARAMETER Argumentos
    Os argumentos do comando, como o usuário passou.

    .PARAMETER Entrada
    O que o comando recebe na entrada padrão, como as linhas que chegaram pelo pipeline. O
    texto vai em UTF-8, com o fim de linha do Linux. Sem entrada, o comando usa a entrada
    padrão do PowerShell, como o terminal, para os prompts do Ansible.

    .EXAMPLE
    Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos 'site.yml'

    Executa ansible-playbook site.yml na distribuição, a partir da pasta atual.

    .EXAMPLE
    Invoke-ComandoNoWsl -Comando 'ansible-playbook' -Argumentos '/dev/stdin' -Entrada (Get-Content site.yml)

    Executa o playbook que chega pela entrada padrão.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Comando,
        [string[]] $Argumentos = @(),
        [AllowEmptyCollection()] [object[]] $Entrada = @()
    )

    $configuracao = Get-Configuracao
    $distribuicao = $configuracao.WslDistribution
    $raizDeMontagem = $configuracao.WslMountRoot

    $distribuicaoFoiEscolhida = [bool] $distribuicao -and [bool] $raizDeMontagem
    if (-not $distribuicaoFoiEscolhida) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoEscolhida')
    }

    $wslEstaInstalado = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $wslEstaInstalado) {
        throw (Get-Mensagem -Nome 'WslNaoEncontrado')
    }

    $pastaAtual = (Get-Location -PSProvider FileSystem).ProviderPath

    $temEntrada = $Entrada.Count -gt 0
    $execucaoDoComando = 'exec "$@"'
    if ($temEntrada) {
        $execucaoDoComando = 'sed -e ''1s/^\xEF\xBB\xBF//'' -e ''s/\r$//'' | "$@"'
    }

    $mensagemDeComandoAusente = Get-Mensagem -Nome 'ComandoAusenteNoWsl' -Valores $Comando

    $script = @(
        'mensagem_de_comando_ausente="$0";'
        'command -v "$1" > /dev/null || { printf ''%s\n'' "$mensagem_de_comando_ausente" >&2; exit 127; };'
        $execucaoDoComando
    ) -join ' '

    $argumentosDoWsl = @(
        '--distribution', $distribuicao
        '--cd', $pastaAtual
        '--exec', 'sh', '-lc', $script, $mensagemDeComandoAusente
        $Comando
    )
    foreach ($argumento in $Argumentos) {
        $argumentosDoWsl += ConvertTo-ArgumentoDoWsl -Argumento $argumento -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem -PastaAtual $pastaAtual
    }

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $variaveisDoAnsible = Get-VariavelDoAnsible -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem -PastaAtual $pastaAtual

    $ErrorActionPreference = 'Continue'
    $codificacaoDoConsole = [Console]::OutputEncoding
    $utf8DoWslOriginal = $env:WSL_UTF8
    $wslenvOriginal = $env:WSLENV
    $valoresOriginaisDoAnsible = @{}
    try {
        foreach ($nome in $variaveisDoAnsible.Keys) {
            $valoresOriginaisDoAnsible[$nome] = [Environment]::GetEnvironmentVariable($nome)
            [Environment]::SetEnvironmentVariable($nome, $variaveisDoAnsible[$nome])
        }
        $env:WSLENV = (@($variaveisDoAnsible.Keys) + @("$wslenvOriginal".Split(':') | Where-Object { $_ })) -join ':'
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        $env:WSL_UTF8 = '1'

        if ($temEntrada) {
            $OutputEncoding = [Text.UTF8Encoding]::new($false)
            $Entrada | wsl @argumentosDoWsl
        }
        else {
            wsl @argumentosDoWsl
        }
    }
    finally {
        $env:WSL_UTF8 = $utf8DoWslOriginal
        $env:WSLENV = $wslenvOriginal
        foreach ($nome in $valoresOriginaisDoAnsible.Keys) {
            [Environment]::SetEnvironmentVariable($nome, $valoresOriginaisDoAnsible[$nome])
        }
        [Console]::OutputEncoding = $codificacaoDoConsole
    }

    $codigoDeSaida = $LASTEXITCODE
    $oWslFalhou = $codigoDeSaida -eq -1
    if ($oWslFalhou) {
        $distribuicaoExiste = $distribuicao -in @(Get-DistribuicaoDoWsl)
        $global:LASTEXITCODE = $codigoDeSaida
        if (-not $distribuicaoExiste) {
            throw (Get-Mensagem -Nome 'DistribuicaoNaoExisteMais' -Valores $distribuicao)
        }
    }
}
