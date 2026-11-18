function Invoke-ComandoNoWsl {
    <#
    .SYNOPSIS
    Executa um comando na distribuição WSL do WinPlaybook, a partir da pasta atual.

    .DESCRIPTION
    O comando roda num login shell, que tem no PATH as pastas do usuário, como
    ~/.local/bin. Os argumentos chegam ao comando sem que um shell os interprete, e os
    caminhos do Windows viram os caminhos deles na distribuição.

    A pasta atual e os caminhos podem estar numa unidade do subst, numa unidade de rede
    mapeada ou num compartilhamento de rede (\\servidor\compartilhamento). Uma unidade vira
    a pasta real para onde aponta, e antes do comando a distribuição monta os
    compartilhamentos de rede, que o WSL não monta sozinho.

    Quando o processo do Windows que chamou o comando termina, como num terminal fechado ou
    numa execução que o VS Code cancela, o comando e todos os processos que ele criou na
    distribuição também terminam.

    Um comando que não existe na distribuição é recusado com o código de saída 127. Quando a
    distribuição não existe mais, o erro explica como instalá-la de novo.

    A saída do comando chega em UTF-8, então os acentos ficam certos também quando o
    PowerShell a captura, como em $saida = ansible-playbook site.yml.

    As variáveis de ambiente do Windows chegam ao comando com os caminhos convertidos, menos
    as que a distribuição define do próprio jeito, como Get-VariavelDoWindows descreve. As
    variáveis do WSLENV chegam como o WSL as passa.

    Quando o agente SSH do Windows está rodando e o relay do agente está na pasta dos shims,
    o comando recebe um SSH_AUTH_SOCK que leva ao agente. Assim o ssh da distribuição usa as
    chaves do agente, e uma chave com passphrase não pede a passphrase. O socket existe só
    enquanto o comando roda.

    Quando o comando roda no ambiente de um projeto com pyproject.toml, os comandos desse
    ambiente que ainda não têm shim, como o molecule, ganham um na pasta dos shims depois
    do comando, por Add-ShimDeComandoDoProjeto.

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

    $usaOAgenteSshDoWindows = $false
    $temPastaDosShims = [bool] $configuracao.ShimFolder
    if ($temPastaDosShims) {
        $caminhoDoRelay = Get-CaminhoDoRelayDoAgenteSsh -PastaDosShims $configuracao.ShimFolder
        $pipeDoAgente = 'openssh-ssh-agent'
        $pipeFoiEscolhido = [bool] $configuracao.SshAgentPipe
        if ($pipeFoiEscolhido) {
            $pipeDoAgente = $configuracao.SshAgentPipe
        }
        $usaOAgenteSshDoWindows = (Test-Path -LiteralPath $caminhoDoRelay) -and (Test-PipeDoWindows -Nome $pipeDoAgente)
    }

    $supervisor = ConvertTo-CaminhoDoWsl -Caminho (Get-CaminhoDoSupervisor) -RaizDeMontagem $raizDeMontagem
    $comandoSupervisionado = '/usr/bin/python3 "$supervisor" "$@"'

    $temEntrada = $Entrada.Count -gt 0
    $execucaoDoComando = "exec $comandoSupervisionado"
    $shellPrecisaContinuar = $usaOAgenteSshDoWindows -or $temEntrada
    if ($shellPrecisaContinuar) {
        $comandoEmSegundoPlano = "$comandoSupervisionado 0<&3 3<&- &"
        if ($temEntrada) {
            $comandoEmSegundoPlano = "sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' 0<&3 3<&- | $comandoSupervisionado &"
        }
        $execucaoDoComando = @(
            'exec 3<&0;'
            $comandoEmSegundoPlano
            'pid_do_comando=$!;'
            'trap ''kill -TERM "$pid_do_comando" 2> /dev/null'' HUP TERM;'
            'trap : INT;'
            'wait "$pid_do_comando"; codigo_de_saida=$?;'
            'while kill -0 "$pid_do_comando" 2> /dev/null; do wait "$pid_do_comando"; codigo_de_saida=$?; done;'
            'exit "$codigo_de_saida"'
        ) -join ' '
    }

    $mensagemDeComandoAusente = Get-Mensagem -Nome 'ComandoAusenteNoWsl' -Valores $Comando

    $leituraDoAgente = @()
    $preparacaoDoAgente = @()
    $argumentosDoAgente = @()
    if ($usaOAgenteSshDoWindows) {
        $leituraDoAgente = 'relay_do_agente="$1"; pipe_do_agente="$2"; shift 2;'
        $preparacaoDoAgente = @(
            'if command -v socat > /dev/null; then'
            'pasta_do_agente=$(mktemp -d /tmp/winplaybook-agente.XXXXXX);'
            'ln -s "$relay_do_agente" "$pasta_do_agente/relay";'
            'export SSH_AUTH_SOCK="$pasta_do_agente/agente.sock";'
            'socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork,umask=177 EXEC:"$pasta_do_agente/relay $pipe_do_agente" 2> /dev/null &'
            'pid_do_socat=$!;'
            'trap ''kill "$pid_do_socat" 2> /dev/null; rm -rf "$pasta_do_agente"'' EXIT;'
            'tentativas=0; while [ ! -S "$SSH_AUTH_SOCK" ] && [ "$tentativas" -lt 100 ]; do sleep 0.01; tentativas=$((tentativas + 1)); done;'
            'fi;'
        )
        $argumentosDoAgente = @(
            ConvertTo-CaminhoDoWsl -Caminho $caminhoDoRelay -RaizDeMontagem $raizDeMontagem
            $pipeDoAgente
        )
    }

    $script = @(
        'mensagem_de_comando_ausente="$0"; supervisor="$1"; shift;'
        $leituraDoAgente
        'export WINPLAYBOOK_COMMAND_NOT_FOUND_MESSAGE="$mensagem_de_comando_ausente";'
        $preparacaoDoAgente
        $execucaoDoComando
    ) -join ' '

    $parametrosDaConversao = @{ Distribuicao = $distribuicao; RaizDeMontagem = $raizDeMontagem; PastaAtual = $pastaAtual; DestinoDeUnidade = (Get-DestinoDeUnidade) }
    $pastaAtualNaDistribuicao = ConvertTo-ArgumentoDoWsl -Argumento $pastaAtual @parametrosDaConversao
    $argumentosNaDistribuicao = @(foreach ($argumento in $Argumentos) { ConvertTo-ArgumentoDoWsl -Argumento $argumento @parametrosDaConversao })
    $variaveisDoWindows = Get-VariavelDoWindows @parametrosDaConversao
    $variaveisDoWindows['WINPLAYBOOK_MOUNT_ROOT'] = $raizDeMontagem
    $pathDoWindows = @(ConvertTo-PathDoWindowsNaDistribuicao -Path "$env:Path" -PastaDosShims "$($configuracao.ShimFolder)")
    $certificadosDoWindows = ConvertTo-CaminhoDoWsl -Caminho (Get-CaminhoDosCertificadosDoWindows) -RaizDeMontagem $raizDeMontagem
    $ambienteDoComando = @{ variaveis = $variaveisDoWindows; pathDoWindows = $pathDoWindows; certificadosDoWindows = $certificadosDoWindows }
    $temRelayDeRede = $temPastaDosShims -and (Test-Path -LiteralPath (Get-CaminhoDoRelayDeRede -PastaDosShims $configuracao.ShimFolder) -PathType Leaf)
    if ($temRelayDeRede) {
        $ambienteDoComando['relayDeRede'] = ConvertTo-CaminhoDoWsl -Caminho (Get-CaminhoDoRelayDeRede -PastaDosShims $configuracao.ShimFolder) -RaizDeMontagem $raizDeMontagem
    }
    $criaShimsDoProjeto = $temPastaDosShims -and [bool] $configuracao.ShimPowerShellPath
    if ($criaShimsDoProjeto) {
        $caminhoDosComandosDoProjeto = Join-Path -Path (Split-Path -Path (Get-CaminhoDoSupervisor) -Parent) -ChildPath "comandos-do-projeto-$([guid]::NewGuid().ToString('N')).txt"
        $ambienteDoComando['comandosDoProjeto'] = ConvertTo-CaminhoDoWsl -Caminho $caminhoDosComandosDoProjeto -RaizDeMontagem $raizDeMontagem
    }
    $ambiente = ConvertTo-Json -InputObject $ambienteDoComando -Compress

    $valoresDoAnsible = @($variaveisDoWindows.Keys | Where-Object { $_.StartsWith('ANSIBLE_', [StringComparison]::Ordinal) } | ForEach-Object { $variaveisDoWindows[$_] })
    $textosDoComando = @($pastaAtualNaDistribuicao) + $argumentosNaDistribuicao + $valoresDoAnsible
    $montagens = @(Get-MontagemNecessaria -Texto $textosDoComando -RaizDeMontagem $raizDeMontagem)
    $temPastaParaMontar = $montagens.Count -gt 0
    if ($temPastaParaMontar) {
        Mount-PastaDoWindows -Distribuicao $distribuicao -Montagem $montagens
    }

    $argumentosDoWsl = @(
        '--distribution', $distribuicao
        '--cd', $pastaAtualNaDistribuicao
        '--exec', 'sh', '-lc', $script, $mensagemDeComandoAusente, $supervisor
        $argumentosDoAgente
        $Comando
    ) + $argumentosNaDistribuicao

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $ErrorActionPreference = 'Continue'
    $codificacaoDoConsole = [Console]::OutputEncoding
    $utf8DoWslOriginal = $env:WSL_UTF8
    $wslenvOriginal = $env:WSLENV
    try {
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        $env:WSL_UTF8 = '1'
        $env:WINPLAYBOOK_ENVIRONMENT = $ambiente
        $env:WSLENV = (@('WINPLAYBOOK_ENVIRONMENT') + @("$wslenvOriginal".Split(':') | Where-Object { $_ })) -join ':'

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
        Remove-Item -LiteralPath 'Env:WINPLAYBOOK_ENVIRONMENT' -ErrorAction SilentlyContinue
        [Console]::OutputEncoding = $codificacaoDoConsole
    }

    $codigoDeSaida = $LASTEXITCODE
    if ($criaShimsDoProjeto) {
        Add-ShimDeComandoDoProjeto -CaminhoDaLista $caminhoDosComandosDoProjeto -PastaDosShims $configuracao.ShimFolder -CaminhoDoPowerShell $configuracao.ShimPowerShellPath
        $global:LASTEXITCODE = $codigoDeSaida
    }
    $oWslFalhou = $codigoDeSaida -eq -1
    if ($oWslFalhou) {
        $distribuicaoExiste = $distribuicao -in @(Get-DistribuicaoDoWsl)
        $global:LASTEXITCODE = $codigoDeSaida
        if (-not $distribuicaoExiste) {
            throw (Get-Mensagem -Nome 'DistribuicaoNaoExisteMais' -Valores $distribuicao)
        }
    }
}
