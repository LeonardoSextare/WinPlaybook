function Get-ScriptDoSupervisor {
    <#
    .SYNOPSIS
    Devolve o script Python, de Python\supervisor.py, que executa o comando na distribuição e o encerra junto com o Windows.

    .DESCRIPTION
    O script recebe nos argumentos o comando e os argumentos dele, e na variável
    WINPLAYBOOK_ENVIRONMENT um JSON com as variáveis de ambiente do
    comando (variaveis), as pastas do Path do Windows na montagem com execução
    (pathDoWindows), o arquivo PEM com os certificados raiz do Windows
    (certificadosDoWindows) e, quando existe, o relay de rede (relayDeRede). Ele executa o comando
    com essas variáveis somadas às da distribuição e sai com o código de
    saída dele, ou com 128 mais o número do sinal que o encerrou. Os processos que o comando
    deixa para trás, mesmo numa sessão própria, como os workers do Ansible, ficam sob o
    script. Um comando que não está no PATH, já com o ambiente do projeto, sai com 127 e
    a mensagem da variável WINPLAYBOOK_COMMAND_NOT_FOUND_MESSAGE no stderr.

    Os programas .com, .exe, .bat e .cmd das pastas do Path do Windows entram no fim do PATH,
    pela pasta ~/.cache/winplaybook/path-do-windows, com o nome completo e com o nome sem a
    extensão, na ordem do Path e do PATHEXT, como no Windows. O nome sem a extensão fica de
    fora para o Python e o pip, que a detecção de interpretador do Ansible procuraria. A pasta
    é gerada de novo só quando as pastas do Path mudam.

    Quando o ~/.ssh/config, que é o config do ssh do Windows, tem caminhos do Windows, o
    script grava uma cópia traduzida em ~/.cache/winplaybook/ssh_config, que o
    /usr/local/bin/ssh usa. Um caminho da pasta .ssh do Windows vira ~/.ssh, os outros viram
    os da raiz de montagem, o IdentityAgent do pipe do agente do Windows vira o
    SSH_AUTH_SOCK, e um ProxyCommand com o ssh.exe do Windows passa a usar o ssh da
    distribuição. Sem caminhos do Windows, a cópia não existe.

    O git da distribuição usa o .gitconfig do perfil do Windows, por uma cópia traduzida em
    ~/.cache/winplaybook/gitconfig que o GIT_CONFIG_GLOBAL aponta: o credential.helper do
    Git for Windows (manager) vira o Git Credential Manager do Windows, pela montagem com
    execução, o core.sshCommand com o ssh.exe vira o ssh da distribuição, e os outros
    caminhos do Windows viram os da raiz de montagem. Sem .gitconfig, a cópia só liga o Git
    Credential Manager, quando o Git for Windows está no Path.

    Sem o EDITOR e o VISUAL no Windows, o EDITOR do ansible-vault é o notepad.exe, que o
    ansible-vault create e edit abrem pelo Path do Windows. O notepad.exe espera a janela
    fechar, como o ansible-vault precisa.

    Os programas da distribuição confiam nos certificados raiz do Windows, além dos do
    Debian, por ~/.cache/winplaybook/certificados.pem, que junta os dois e é gerado de novo
    só quando um deles muda. O SSL_CERT_FILE, o REQUESTS_CA_BUNDLE, o CURL_CA_BUNDLE e o
    GIT_SSL_CAINFO apontam para ele, a não ser que o Windows já defina a variável.

    Quando a pasta atual, ou uma acima dela, tem um pyproject.toml com o ansible ou o
    ansible-core nas dependências, o comando roda no ambiente desse projeto, como o uv run.
    O uv sync prepara o ambiente em ~/.cache/winplaybook/projetos, no disco da distribuição,
    um por projeto, e ele recebe o pacote de Get-ArquivoDoHookDoAnsible. O PATH começa
    pelo ambiente do projeto e perde os comandos do ambiente global, menos o uv e o uvx. Com
    comandosDoProjeto no JSON, o script grava nesse arquivo, um por linha, os comandos do
    ambiente do projeto, sem os do próprio Python (python, pip, pydoc e activate).

    Com log no JSON, o caminho do log do WinPlaybook na distribuição, o script acrescenta a
    ele, no fim, uma linha DEBUG com o tempo de cada preparação e o do comando.

    Com o relay de rede, uma conexão TCP ao localhost da distribuição (127.0.0.1 ou ::1)
    numa porta em que o Windows escuta, e a distribuição não, chega ao localhost do Windows.
    Uma regra do nftables leva essas conexões à porta 47999, onde o supervisor as repassa ao
    relay, e a lista de portas acompanha o Windows a cada segundo. Com comandos em paralelo,
    um supervisor só cuida da ponte, e outro assume quando ele termina. O comando começa
    depois que a ponte aplica a primeira lista de portas, ou depois de 5 segundos.

    Quando a entrada padrão não é um terminal, ela chega ao comando por um pipe do próprio
    usuário, e o comando pode reabri-la pelo /dev/stdin. O pipe que o WSL entrega é do root.

    Quando o processo do Windows que chamou o WSL termina, o script recebe SIGHUP, ou SIGTERM,
    e encerra o comando e todos esses processos. Um Ctrl+C chega ao comando, que decide o que
    fazer, e o script continua esperando por ele.

    .EXAMPLE
    $script = Get-ScriptDoSupervisor

    Devolve o código Python, para o python3 da distribuição executar com o comando nos
    argumentos.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $caminho = Join-Path -Path $ExecutionContext.SessionState.Module.ModuleBase -ChildPath 'Python\supervisor.py'
    return [IO.File]::ReadAllText($caminho)
}
