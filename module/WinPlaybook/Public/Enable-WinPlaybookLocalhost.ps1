function Enable-WinPlaybookLocalhost {
    <#
    .SYNOPSIS
    Liga o localhost_windows, o host que faz o Ansible configurar a própria máquina Windows.

    .DESCRIPTION
    Os playbooks passam a ter o host localhost_windows sem que ele esteja no inventário, como
    o Ansible faz com o localhost. Ele conecta no Windows pelo SSH, com os módulos
    ansible.windows, enquanto o localhost continua sendo o nó de controle.

    O comando precisa de administrador, e o Windows pede a aprovação quando o PowerShell não
    é elevado. Ele baixa o OpenSSH da release oficial da Microsoft no GitHub para uma pasta
    só do WinPlaybook, sem instalar nada no Windows, cria o serviço WinPlaybookSshd, que só escuta no 127.0.0.1 da porta 47022 e só aceita a chave que fica
    na distribuição, sem senha, e guarda a configuração. O Disable-WinPlaybookLocalhost e o
    Uninstall-WinPlaybook desfazem tudo.

    .EXAMPLE
    Enable-WinPlaybookLocalhost

    .LINK
    https://docs.ansible.com/ansible/latest/os_guide/windows_ssh.html

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/enable-winplaybooklocalhost/
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

    $plano = New-Plano -Itens @(Get-PassoDoLocalhostWindows)
    try {
        $ehAdministrador = Test-Administrador
        if (-not $ehAdministrador) {
            Invoke-ComoAdministrador -Comando 'Enable-WinPlaybookLocalhost -Confirm:$false' -IdDaAprovacao 'localhost.aprovacao'
        }
        else {
            Write-ProgressoDoAdministrador -Id 'localhost.chave'
            $chavePublica = New-ChaveDoLocalhostWindows -Distribuicao $configuracao.WslDistribution
            Write-ProgressoDoAdministrador -Id 'localhost.chave' -Fim

            Write-ProgressoDoAdministrador -Id 'localhost.openssh'
            $pastaDoOpenSsh = Install-OpenSshDoWinPlaybook
            Write-ProgressoDoAdministrador -Id 'localhost.openssh' -Fim

            Write-ProgressoDoAdministrador -Id 'localhost.servico'
            $usuario = Get-UsuarioDoLocalhostWindows
            $porta = 47022
            Install-SshdDoWinPlaybook -ChavePublica $chavePublica -Usuario $usuario -Porta $porta -PastaDoOpenSsh $pastaDoOpenSsh
            $configuracao['LocalhostWindowsPort'] = $porta
            $configuracao['LocalhostWindowsUser'] = $usuario
            $configuracao['LocalhostWindowsDeclined'] = $null
            Save-Configuracao -Configuracao $configuracao
            Write-ProgressoDoAdministrador -Id 'localhost.servico' -Fim
        }
    }
    finally {
        Close-Plano -Plano $plano
    }

    if (-not $plano.Aninhado) {
        Write-Host ''
        Write-Host "$(Get-Mensagem -Nome 'Pronto') " -ForegroundColor Green -NoNewline
        Write-Host "$(Get-Mensagem -Nome 'TesteCom') " -NoNewline
        Write-Host 'ansible localhost_windows -m ansible.windows.win_ping' -ForegroundColor Cyan
    }
}
