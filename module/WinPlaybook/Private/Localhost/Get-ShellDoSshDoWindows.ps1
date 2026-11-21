function Get-ShellDoSshDoWindows {
    <#
    .SYNOPSIS
    Devolve o tipo de shell do Ansible que combina com o shell padrão do OpenSSH do Windows.

    .DESCRIPTION
    Lê o DefaultShell do OpenSSH, que o serviço WinPlaybookSshd usa como o OpenSSH Server do
    Windows. Devolve powershell quando ele aponta para o powershell.exe ou para o pwsh.exe, e
    cmd quando aponta para outro programa ou não está definido, que é o padrão do OpenSSH.

    .EXAMPLE
    Get-ShellDoSshDoWindows

    Devolve powershell numa máquina com o DefaultShell no Windows PowerShell.

    .LINK
    https://learn.microsoft.com/windows-server/administration/openssh/openssh-server-configuration#configuring-the-default-shell-for-openssh-in-windows
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $shellPadrao = "$(Get-ValorDoRegistro -Chave 'HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH' -Nome 'DefaultShell')"
    $nomeDoPrograma = [IO.Path]::GetFileName($shellPadrao.Trim().Trim('"'))
    $ehPowerShell = $nomeDoPrograma -in 'powershell.exe', 'pwsh.exe'
    if ($ehPowerShell) {
        return 'powershell'
    }

    return 'cmd'
}
