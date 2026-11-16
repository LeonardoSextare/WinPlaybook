function Get-CulturaDaInterface {
    <#
    .SYNOPSIS
    Devolve o idioma da interface do Windows do usuário, como pt-BR.

    .EXAMPLE
    Get-CulturaDaInterface

    Devolve pt-BR num Windows em português do Brasil.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables#psuiculture
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $PSUICulture
}
