function Install-AnsibleNaDistribuicao {
    <#
    .SYNOPSIS
    Instala o Ansible, o ansible-lint, o pywinrm e o argcomplete na distribuição WSL do WinPlaybook, com o uv.

    .DESCRIPTION
    Instala o uv no usuário winplaybook quando ele ainda não está lá e, num ambiente só, o
    pacote ansible, com as collections dele, o ansible-lint, o pywinrm, o argcomplete, que gera o
    autocomplete dos comandos, e os pacotes Python
    pedidos. Os comandos do ansible-core, do ansible-lint e dos pacotes pedidos, como o
    molecule, ficam em ~/.local/bin. Um pacote pedido por URL ou caminho não expõe comandos.

    O ansible-core declara só a versão mínima do Python, e uma versão nova demais do Python
    pode quebrá-lo. Por isso o uv tenta do Python mais novo para o mais antigo e fica com o
    primeiro em que o ansible --version funciona. Rodar de novo troca a instalação pela
    pedida.

    O ambiente recebe também o pacote de Get-ArquivoDoHookDoAnsible, que adapta o Ansible
    ao Windows, e perde o módulo winplaybook_caminhos_do_windows das versões anteriores.

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
        'arquivos_do_hook="$1"; executaveis="$2"; pacote="$3"; shift 3;'
        'for extra in "$@"; do set -- "$@" --with "$extra"; shift; done;'
        'ultima_saida="";'
        'for versao in $(uv python list 2> /dev/null | sed -n ''s/^cpython-\(3\.[0-9]*\)\.[0-9]*-linux.*/\1/p'' | sort -t. -k2 -n -r -u); do'
        'if ultima_saida=$(uv tool install --force --python "$versao" "$pacote" --with-executables-from "$executaveis" --with pywinrm --with argcomplete "$@" 2>&1) && ultima_saida=$("$HOME/.local/bin/ansible" --version 2>&1); then'
        'site_packages=$("$HOME/.local/share/uv/tools/ansible/bin/python" -c ''import sysconfig; print(sysconfig.get_paths()["purelib"])'');'
        'rm -rf "$site_packages/winplaybook_caminhos_do_windows.py" "$site_packages/winplaybook_ansible"; mkdir -p "$site_packages/winplaybook_ansible";'
        'printf ''%s\n'' "$arquivos_do_hook" | while read -r nome conteudo; do printf ''%s'' "$conteudo" | base64 -d > "$site_packages/winplaybook_ansible/$nome"; done;'
        'printf ''import winplaybook_ansible\n'' > "$site_packages/winplaybook.pth";'
        'exit 0;'
        'fi;'
        'done;'
        'printf ''%s\n'' "$ultima_saida" >&2; exit 1'
    ) -join ' '

    $arquivosDoHook = @(foreach ($arquivo in Get-ArquivoDoHookDoAnsible) { "$($arquivo.Nome) $([Convert]::ToBase64String($arquivo.Conteudo))" }) -join "`n"
    $nomesDosPacotes = @(foreach ($pacote in $PacotesPython) { [regex]::Match($pacote, '^[A-Za-z0-9][A-Za-z0-9._-]*(?=\s*([\[<>=!~;@]|$))').Value })
    $executaveis = (@('ansible-core', 'ansible-lint') + @($nomesDosPacotes | Where-Object { $_ })) -join ','
    $argumentos = @($arquivosDoHook, $executaveis, $pacoteDoAnsible) + $PacotesPython
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script $script -Argumentos $argumentos -Usuario 'winplaybook'
    $instalou = $resultado.CodigoDeSaida -eq 0
    if (-not $instalou) {
        throw (Get-Mensagem -Nome 'AnsibleNaoInstalado' -Valores $Nome, $resultado.Saida)
    }
}
