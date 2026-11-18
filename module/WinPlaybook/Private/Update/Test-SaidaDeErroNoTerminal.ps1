function Test-SaidaDeErroNoTerminal {
    <#
    .SYNOPSIS
    Diz se o stderr do processo vai para o terminal, e não para um arquivo ou outro programa.

    .EXAMPLE
    Test-SaidaDeErroNoTerminal

    Devolve $true num terminal, e $false quando outro programa, como o VS Code, lê o stderr.

    .LINK
    https://learn.microsoft.com/dotnet/api/system.console.iserrorredirected
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return -not [Console]::IsErrorRedirected
}
