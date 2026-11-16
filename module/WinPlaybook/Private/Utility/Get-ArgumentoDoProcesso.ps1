function Get-ArgumentoDoProcesso {
    <#
    .SYNOPSIS
    Devolve os argumentos com que o processo atual foi aberto, como o Windows os separa da linha de comando.

    .DESCRIPTION
    O primeiro item é o programa do processo. Os outros chegam como o programa que abriu o
    processo os passou, antes de o PowerShell interpretá-los.

    .EXAMPLE
    Get-ArgumentoDoProcesso

    Devolve o PowerShell, -NoProfile, -File, o script e os argumentos dele num PowerShell aberto com -File.

    .LINK
    https://learn.microsoft.com/dotnet/api/system.environment.getcommandlineargs
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return [Environment]::GetCommandLineArgs()
}
