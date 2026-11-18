function Install-AnsibleNaDistribuicao {
    <#
    .SYNOPSIS
    Instala o Ansible, o ansible-lint e o pywinrm na distribuição WSL do WinPlaybook, com o uv.

    .DESCRIPTION
    Instala o uv no usuário winplaybook quando ele ainda não está lá e, num ambiente só, o
    pacote ansible, com as collections dele, o ansible-lint, o pywinrm e os pacotes Python
    pedidos. Os comandos do ansible-core, do ansible-lint e dos pacotes pedidos, como o
    molecule, ficam em ~/.local/bin. Um pacote pedido por URL ou caminho não expõe comandos.

    O ansible-core declara só a versão mínima do Python, e uma versão nova demais do Python
    pode quebrá-lo. Por isso o uv tenta do Python mais novo para o mais antigo e fica com o
    primeiro em que o ansible --version funciona. Rodar de novo troca a instalação pela
    pedida.

    O ambiente recebe também o módulo de Get-ScriptDosCaminhosDoWindows, que faz o Ansible
    aceitar caminhos do Windows nos playbooks, no inventário e no ansible.cfg.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .PARAMETER VersaoDoAnsible
    A versão do pacote ansible, como 13.0.0 ou 13.*. Vazia, instala a mais nova.

    .PARAMETER PacotesPython
    Os pacotes Python que entram junto com o Ansible, como boto3, no formato do pip.

    .EXAMPLE
    Install-AnsibleNaDistribuicao -Nome 'WinPlaybook' -VersaoDoAnsible '' -PacotesPython 'boto3'

    .LINK
    https://docs.astral.sh/uv/guides/tools/
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [AllowEmptyString()] [string] $VersaoDoAnsible,
        [AllowEmptyCollection()] [string[]] $PacotesPython = @()
    )

    $pacoteDoAnsible = 'ansible'
    $versaoFoiEscolhida = [bool] $VersaoDoAnsible
    if ($versaoFoiEscolhida) {
        $pacoteDoAnsible = "ansible==$VersaoDoAnsible"
    }

    $script = @(
        'export PATH="$HOME/.local/bin:$PATH";'
        'command -v uv > /dev/null || curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh > /dev/null 2>&1;'
        'caminhos_do_windows="$1"; executaveis="$2"; pacote="$3"; shift 3;'
        'for extra in "$@"; do set -- "$@" --with "$extra"; shift; done;'
        'ultima_saida="";'
        'for versao in $(uv python list 2> /dev/null | sed -n ''s/^cpython-\(3\.[0-9]*\)\.[0-9]*-linux.*/\1/p'' | sort -t. -k2 -n -r -u); do'
        'if ultima_saida=$(uv tool install --force --python "$versao" "$pacote" --with-executables-from "$executaveis" --with pywinrm "$@" 2>&1) && ultima_saida=$("$HOME/.local/bin/ansible" --version 2>&1); then'
        'site_packages=$("$HOME/.local/share/uv/tools/ansible/bin/python" -c ''import sysconfig; print(sysconfig.get_paths()["purelib"])'');'
        'printf ''%s'' "$caminhos_do_windows" | base64 -d > "$site_packages/winplaybook_caminhos_do_windows.py";'
        'printf ''import winplaybook_caminhos_do_windows\n'' > "$site_packages/winplaybook.pth";'
        'exit 0;'
        'fi;'
        'done;'
        'printf ''%s\n'' "$ultima_saida" >&2; exit 1'
    ) -join ' '

    $caminhosDoWindows = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-ScriptDosCaminhosDoWindows)))
    $nomesDosPacotes = @(foreach ($pacote in $PacotesPython) { [regex]::Match($pacote, '^[A-Za-z0-9][A-Za-z0-9._-]*(?=\s*([\[<>=!~;@]|$))').Value })
    $executaveis = (@('ansible-core', 'ansible-lint') + @($nomesDosPacotes | Where-Object { $_ })) -join ','
    $argumentos = @($caminhosDoWindows, $executaveis, $pacoteDoAnsible) + $PacotesPython
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script $script -Argumentos $argumentos -Usuario 'winplaybook'
    $instalou = $resultado.CodigoDeSaida -eq 0
    if (-not $instalou) {
        throw (Get-Mensagem -Nome 'AnsibleNaoInstalado' -Valores $Nome, $resultado.Saida)
    }
}
