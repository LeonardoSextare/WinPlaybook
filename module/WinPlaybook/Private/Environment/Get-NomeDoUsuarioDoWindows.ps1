function Get-NomeDoUsuarioDoWindows {
    <#
    .SYNOPSIS
    Devolve o nome do usuário do Windows que executa o comando.

    .DESCRIPTION
    É o nome que o ssh do Windows usa quando a conexão não define um usuário.

    .EXAMPLE
    Get-NomeDoUsuarioDoWindows

    Devolve leonardo.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return [Environment]::UserName
}
