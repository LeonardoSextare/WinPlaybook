function Test-SessaoInterativa {
    <#
    .SYNOPSIS
    Diz se o PowerShell atual pode fazer perguntas ao usuário.

    .DESCRIPTION
    É interativo quando a sessão do Windows é interativa e a entrada vem do teclado, e não
    de um arquivo ou de outro programa, como num script do CI.

    .EXAMPLE
    Test-SessaoInterativa
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
}
