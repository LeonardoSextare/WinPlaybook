function Disable-WinPlaybookLocalhost {
    <#
    .SYNOPSIS
    Desliga o localhost_windows e desfaz o que o Enable-WinPlaybookLocalhost fez.

    .DESCRIPTION
    Precisa de administrador, e o Windows pede a aprovação quando o PowerShell não é
    elevado. Apaga o serviço WinPlaybookSshd, a configuração dele e o OpenSSH que o WinPlaybook
    baixou. O recurso OpenSSH Server do Windows só é desinstalado quando uma versão anterior
    do WinPlaybook o instalou. Sem o localhost_windows ligado, nada
    muda.

    .EXAMPLE
    Disable-WinPlaybookLocalhost

    .LINK
    https://leonardosextare.github.io/WinPlaybook/pt-br/disable-winplaybooklocalhost/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    $configuracao = Get-Configuracao
    $estaLigado = [bool] $configuracao['LocalhostWindowsPort']
    if (-not $estaLigado) {
        return
    }

    $confirmou = $PSCmdlet.ShouldProcess('localhost_windows', (Get-Mensagem -Nome 'DesativarLocalhostWindows'))
    if (-not $confirmou) {
        return
    }

    $ehAdministrador = Test-Administrador
    if (-not $ehAdministrador) {
        Invoke-ComoAdministrador -Comando 'Disable-WinPlaybookLocalhost -Confirm:$false'
        return
    }

    Remove-SshdDoWinPlaybook
    $instalouOOpenSsh = [bool] $configuracao['OpenSshServerInstalledByWinPlaybook']
    if ($instalouOOpenSsh) {
        Uninstall-ServidorOpenSsh
    }

    $configuracao['LocalhostWindowsPort'] = $null
    $configuracao['LocalhostWindowsUser'] = $null
    $configuracao['OpenSshServerInstalledByWinPlaybook'] = $null
    Save-Configuracao -Configuracao $configuracao
}
