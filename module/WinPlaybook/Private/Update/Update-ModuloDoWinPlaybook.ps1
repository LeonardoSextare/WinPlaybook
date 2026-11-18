function Update-ModuloDoWinPlaybook {
    <#
    .SYNOPSIS
    Atualiza o módulo WinPlaybook pela PowerShell Gallery, com o gerenciador da edição do PowerShell.

    .DESCRIPTION
    Usa o Update-PSResource quando ele existe, como no PowerShell 7.4, e o Update-Module nas
    outras edições, como o Windows PowerShell 5.1. Falha quando o módulo não foi instalado
    pela Gallery, como pelo código-fonte.

    .EXAMPLE
    Update-ModuloDoWinPlaybook

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/update-psresource
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $temPSResourceGet = [bool] (Get-Command -Name 'Update-PSResource' -ErrorAction SilentlyContinue)
    if ($temPSResourceGet) {
        Update-PSResource -Name 'WinPlaybook' -ErrorAction Stop
        return
    }

    Update-Module -Name 'WinPlaybook' -ErrorAction Stop
}
