function Get-ArquivoDoHookDoAnsible {
    <#
    .SYNOPSIS
    Devolve os arquivos do pacote Python winplaybook_ansible, que adapta o Ansible ao Windows.

    .DESCRIPTION
    O pacote fica em Python\winplaybook_ansible, na pasta do módulo, e o Python do Ansible o
    carrega ao iniciar, por um arquivo .pth no ambiente dele. Cada parte do pacote cuida de
    um assunto:

    - caminhos: converte os caminhos do Windows onde o Ansible expande caminhos, como no
      os.path.expanduser, nos path_dwim do DataLoader, nas listas de caminhos do ansible.cfg,
      separadas por ponto e vírgula, e nos caminhos sem aspas de um inventário INI;
    - saida: mostra os caminhos do Windows, com barras normais, no que os comandos do Ansible
      escrevem, e, nos comandos do nó de controle, os caminhos do disco da distribuição como
      caminhos do Windows ou de \\wsl.localhost;
    - scripts: roda pela extensão os scripts das pastas do Windows, que não têm a permissão de
      execução, e tira os CR dos scripts com shebang que o ansible.builtin.script envia;
    - localhost_windows: cria o host implícito localhost_windows, com a porta, o usuário e a
      chave da variável WINPLAYBOOK_LOCALHOST_WINDOWS.

    A raiz de montagem vem da variável WINPLAYBOOK_MOUNT_ROOT, e o padrão é /mnt/. Os
    arquivos vêm em ordem de nome, cada um com o nome (Nome) e o conteúdo em bytes
    (Conteudo).

    .EXAMPLE
    $arquivos = Get-ArquivoDoHookDoAnsible

    Devolve os arquivos, para o Install-AnsibleNaDistribuicao gravar no ambiente do Ansible.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $pasta = Join-Path -Path $ExecutionContext.SessionState.Module.ModuleBase -ChildPath 'Python\winplaybook_ansible'
    [string[]] $nomes = @(Get-ChildItem -LiteralPath $pasta -Filter '*.py' -File | ForEach-Object { $_.Name })
    [Array]::Sort($nomes, [StringComparer]::Ordinal)
    foreach ($nome in $nomes) {
        [pscustomobject]@{
            Nome     = $nome
            Conteudo = [IO.File]::ReadAllBytes((Join-Path -Path $pasta -ChildPath $nome))
        }
    }
}
