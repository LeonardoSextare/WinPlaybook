function Get-PastaDoOpenSshDoWinPlaybook {
    <#
    .SYNOPSIS
    Devolve a pasta em que o WinPlaybook guarda o OpenSSH que o localhost_windows usa.

    .DESCRIPTION
    A pasta fica em %ProgramData%\WinPlaybook\openssh, ao lado da configuração do serviço,
    em %ProgramData%\WinPlaybook\ssh.

    .EXAMPLE
    Get-PastaDoOpenSshDoWinPlaybook
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path ([Environment]::GetFolderPath('CommonApplicationData')) -ChildPath 'WinPlaybook\openssh'
}
