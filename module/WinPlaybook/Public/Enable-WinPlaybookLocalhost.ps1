function Enable-WinPlaybookLocalhost {
    <#
    .SYNOPSIS
    Liga o localhost_windows, o host que faz o Ansible configurar a própria máquina Windows.

    .DESCRIPTION
    Os playbooks passam a ter o host localhost_windows sem que ele esteja no inventário, como
    o Ansible faz com o localhost. Ele conecta no Windows pelo SSH, com os módulos
    ansible.windows, enquanto o localhost continua sendo o nó de controle.

    O comando precisa de administrador, e o Windows pede a aprovação quando o PowerShell não
    é elevado. Ele instala o recurso opcional OpenSSH Server quando falta, cria o serviço
    WinPlaybookSshd, que só escuta no 127.0.0.1 da porta 47022 e só aceita a chave que fica
    na distribuição, sem senha, e guarda a configuração. O Disable-WinPlaybookLocalhost e o
    Uninstall-WinPlaybook desfazem tudo.

    .EXAMPLE
    Enable-WinPlaybookLocalhost

    .LINK
    https://docs.ansible.com/ansible/latest/os_guide/windows_ssh.html
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    $configuracao = Get-Configuracao
    $temDistribuicao = [bool] $configuracao.WslDistribution
    if (-not $temDistribuicao) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoEscolhida')
    }

    $confirmou = $PSCmdlet.ShouldProcess('localhost_windows', (Get-Mensagem -Nome 'AtivarLocalhostWindows'))
    if (-not $confirmou) {
        return
    }

    $ehAdministrador = Test-Administrador
    if (-not $ehAdministrador) {
        Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost -Confirm:$false'
        return
    }

    $chavePublica = New-ChaveDoLocalhostWindows -Distribuicao $configuracao.WslDistribution
    $usuario = Get-UsuarioDoLocalhostWindows
    $porta = 47022
    $instalouOOpenSsh = Install-ServidorOpenSsh
    Install-SshdDoWinPlaybook -ChavePublica $chavePublica -Usuario $usuario -Porta $porta

    $configuracao['LocalhostWindowsPort'] = $porta
    $configuracao['LocalhostWindowsUser'] = $usuario
    $configuracao['LocalhostWindowsDeclined'] = $null
    $configuracao['OpenSshServerInstalledByWinPlaybook'] = $instalouOOpenSsh -or [bool] $configuracao['OpenSshServerInstalledByWinPlaybook']
    Save-Configuracao -Configuracao $configuracao
}
