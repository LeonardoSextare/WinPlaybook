function Get-PastaDoSshDeTeste {
    <#
    .SYNOPSIS
    Devolve a pasta do Windows que a distribuição WSL dos testes usa como ~/.ssh.

    .DESCRIPTION
    A pasta fica em %LOCALAPPDATA%\WinPlaybookTestes\ssh e faz nos testes o papel da pasta
    .ssh do usuário, que os testes nunca usam.

    .EXAMPLE
    $pastaDoSsh = Get-PastaDoSshDeTeste
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\ssh'
}

function Initialize-DistribuicaoWslDeTeste {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL dos testes, como o Install-WinPlaybook prepara a distribuição WinPlaybook, e devolve o nome dela.

    .DESCRIPTION
    A distribuição se chama WinPlaybookE2E e guarda o disco em
    %LOCALAPPDATA%\WinPlaybookTestes\WinPlaybookE2E. As funções do próprio módulo a criam e
    a preparam na primeira vez, com internet, e as outras vezes reaproveitam a distribuição
    já preparada. O ~/.ssh dela é a pasta de Get-PastaDoSshDeTeste, o perfil do Windows dela
    é a pasta %LOCALAPPDATA%\WinPlaybookTestes\perfil, e o usuário do Windows é
    usuario-de-teste. O módulo WinPlaybook precisa estar importado.

    .EXAMPLE
    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $parametros = @{
        Nome          = 'WinPlaybookE2E'
        Pasta         = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\WinPlaybookE2E'
        PastaDoSsh    = Get-PastaDoSshDeTeste
        PastaDoPerfil = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\perfil'
    }
    $null = New-Item -ItemType Directory -Path $parametros.PastaDoSsh -Force
    InModuleScope WinPlaybook -Parameters $parametros {
        $estaInstalada = $Nome -in @(Get-DistribuicaoDoWsl)
        if (-not $estaInstalada) {
            New-DistribuicaoDoWinPlaybook -Nome $Nome -Pasta $Pasta
        }

        $verificacao = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script 'grep -qx "default=$1" /etc/wsl.conf && mountpoint -q "$HOME/.ssh" && command -v rsync > /dev/null && command -v socat > /dev/null && grep -q "^User " /etc/ssh/ssh_config.d/winplaybook.conf && test "$(readlink "$HOME/.ansible/roles")" = "$(wslpath -a "$2")/.ansible/roles" && test -x /usr/local/lib/winplaybook/executar-bat && test -x "$HOME/.local/bin/ansible-playbook" && ls "$HOME"/.local/share/uv/tools/ansible/lib/python3*/site-packages/winplaybook.pth > /dev/null 2>&1' -Argumentos 'winplaybook', $PastaDoPerfil -Usuario 'winplaybook'
        $estaPreparada = $verificacao.CodigoDeSaida -eq 0
        if (-not $estaPreparada) {
            Initialize-DistribuicaoDoWinPlaybook -Nome $Nome -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'usuario-de-teste'
            Install-AnsibleNaDistribuicao -Nome $Nome -VersaoDoAnsible ''
        }
    }

    return $parametros.Nome
}
