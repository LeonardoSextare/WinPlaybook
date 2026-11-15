function Get-PastaDeConfiguracao {
    <#
    .SYNOPSIS
    Devolve a pasta onde o WinPlaybook guarda a configuração.

    .DESCRIPTION
    A pasta é sempre a mesma, mesmo quando os shims foram instalados em outra pasta.

    .EXAMPLE
    Get-PastaDeConfiguracao

    Devolve C:\Users\<usuário>\AppData\Local\WinPlaybook.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path $env:LOCALAPPDATA -ChildPath 'WinPlaybook'
}
