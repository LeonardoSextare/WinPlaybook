function Get-CaminhoDoRelayDoAgenteSsh {
    <#
    .SYNOPSIS
    Devolve o caminho do relay do agente SSH na pasta dos shims.

    .DESCRIPTION
    O relay fica na subpasta exe da pasta dos shims, que não está no Path do usuário.

    .PARAMETER PastaDosShims
    A pasta dos shims, como a ShimFolder da configuração.

    .EXAMPLE
    Get-CaminhoDoRelayDoAgenteSsh -PastaDosShims 'C:\Tools\WinPlaybook\bin'

    Devolve C:\Tools\WinPlaybook\bin\exe\relay-do-agente-ssh.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $PastaDosShims
    )

    return Join-Path -Path $PastaDosShims -ChildPath 'exe\relay-do-agente-ssh.exe'
}
