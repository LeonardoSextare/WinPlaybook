function Invoke-ComandoNoWsl {
    <#
    .SYNOPSIS
    Executa um comando na distribuição WSL escolhida na instalação, a partir da pasta atual.

    .DESCRIPTION
    O comando roda num login shell, que tem no PATH as pastas do usuário, como
    ~/.local/bin. Os argumentos chegam ao comando sem que um shell os interprete, e os
    caminhos do Windows viram os caminhos deles na distribuição.

    Um comando que não existe na distribuição, ou que só existe numa unidade do Windows, é
    recusado com o código de saída 127.

    A saída do comando chega em UTF-8, então os acentos ficam certos também quando o
    PowerShell a captura, como em $saida = ansible-playbook site.yml.

    O Ansible ignora o ansible.cfg de uma pasta com permissão de escrita para todos, como as
    unidades do Windows na distribuição. Numa pasta assim, o ansible.cfg da pasta atual vai
    no ANSIBLE_CONFIG, a não ser que a variável já esteja definida, e o Ansible o lê como no
    Linux.

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
        throw 'O WinPlaybook não sabe qual distribuição WSL roda o Ansible. Escolha com: Install-WinPlaybookShim -Distribution <nome> (o wsl --list mostra as distribuições).'
    }

    $wslEstaInstalado = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $wslEstaInstalado) {
        throw 'O WSL não foi encontrado. O WinPlaybook roda o Ansible numa distribuição WSL: instale o WSL com wsl --install e tente de novo.'
    }

    $pastaAtual = (Get-Location -PSProvider FileSystem).ProviderPath

    $temEntrada = $Entrada.Count -gt 0
    $execucaoDoComando = 'exec "$@"'
    if ($temEntrada) {
        $execucaoDoComando = 'sed -e ''1s/^\xEF\xBB\xBF//'' -e ''s/\r$//'' | "$@"'
    }

    $script = @(
        'raiz_de_montagem="$0"; comando="$1";'
        'case $(command -v "$comando") in'
        '"") echo "WinPlaybook: comando $comando ausente no WSL. Instale-o no WSL, ou rode Install-WinPlaybookShim para atualizar os comandos." >&2; exit 127 ;;'
        '"$raiz_de_montagem"*) echo "WinPlaybook: comando $comando ausente no WSL, existe apenas no Windows ($(command -v "$comando")). Instale-o no WSL." >&2; exit 127 ;;'
        'esac;'
        'case $(stat -c %A . 2>/dev/null) in ????????w?)'
        'if [ -z "${ANSIBLE_CONFIG+definida}" ] && [ -f ansible.cfg ]; then export ANSIBLE_CONFIG="$PWD/ansible.cfg"; fi ;;'
        'esac;'
        $execucaoDoComando
    ) -join ' '

    $argumentosDoWsl = @(
        '--distribution', $distribuicao
        '--cd', $pastaAtual
        '--exec', 'sh', '-lc', $script, $raizDeMontagem
        $Comando
    )
    foreach ($argumento in $Argumentos) {
        $argumentosDoWsl += ConvertTo-ArgumentoDoWsl -Argumento $argumento -Distribuicao $distribuicao -RaizDeMontagem $raizDeMontagem -PastaAtual $pastaAtual
    }

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $ErrorActionPreference = 'Continue'
    $codificacaoDoConsole = [Console]::OutputEncoding
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    try {
        if ($temEntrada) {
            $OutputEncoding = [Text.UTF8Encoding]::new($false)
            $Entrada | wsl @argumentosDoWsl
        }
        else {
            wsl @argumentosDoWsl
        }
    }
    finally {
        [Console]::OutputEncoding = $codificacaoDoConsole
    }
}
