function Uninstall-ServidorOpenSsh {
    <#
    .SYNOPSIS
    Desinstala o recurso opcional OpenSSH Server do Windows.

    .DESCRIPTION
    Precisa de administrador. O WinPlaybook só chama este comando quando foi ele que
    instalou o recurso, pelo Install-ServidorOpenSsh.

    .EXAMPLE
    Uninstall-ServidorOpenSsh

    .LINK
    https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $recurso = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop | Select-Object -First 1
    $null = Remove-WindowsCapability -Online -Name $recurso.Name -ErrorAction Stop
}
