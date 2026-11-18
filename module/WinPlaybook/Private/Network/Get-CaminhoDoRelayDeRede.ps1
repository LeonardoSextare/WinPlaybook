function Get-CaminhoDoRelayDeRede {
    <#
    .SYNOPSIS
    Devolve o caminho do relay de rede na pasta dos shims.

    .DESCRIPTION
    O relay fica na subpasta exe da pasta dos shims, que não está no Path do usuário.

    .PARAMETER PastaDosShims
    A pasta dos shims, como a ShimFolder da configuração.

    .EXAMPLE
    Get-CaminhoDoRelayDeRede -PastaDosShims 'C:\Tools\WinPlaybook\bin'

    Devolve C:\Tools\WinPlaybook\bin\exe\relay-de-rede.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $PastaDosShims
    )

    return Join-Path -Path $PastaDosShims -ChildPath 'exe\relay-de-rede.exe'
}
