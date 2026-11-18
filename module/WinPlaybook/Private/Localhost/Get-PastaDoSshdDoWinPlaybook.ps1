function Get-PastaDoSshdDoWinPlaybook {
    <#
    .SYNOPSIS
    Devolve a pasta da configuração do serviço SSH do WinPlaybook.

    .EXAMPLE
    Get-PastaDoSshdDoWinPlaybook

    Devolve C:\ProgramData\WinPlaybook\ssh.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path ([Environment]::GetFolderPath('CommonApplicationData')) -ChildPath 'WinPlaybook\ssh'
}
