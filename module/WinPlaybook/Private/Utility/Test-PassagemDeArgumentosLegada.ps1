function Test-PassagemDeArgumentosLegada {
    <#
    .SYNOPSIS
    Diz se o PowerShell passa argumentos a programas sem escapar as aspas.

    .DESCRIPTION
    O Windows PowerShell 5.1 e o PowerShell 7.0 a 7.2 sempre passam assim. O PowerShell 7.3
    em diante escapa as aspas, a não ser que $PSNativeCommandArgumentPassing seja Legacy.

    .EXAMPLE
    Test-PassagemDeArgumentosLegada

    Devolve True no Windows PowerShell 5.1.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_preference_variables#psnativecommandargumentpassing
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $temPassagemModerna = $PSVersionTable.PSVersion -ge [version] '7.3'
    if (-not $temPassagemModerna) {
        return $true
    }

    $formaDePassagem = Get-Variable -Name 'PSNativeCommandArgumentPassing' -ValueOnly -ErrorAction SilentlyContinue
    return $formaDePassagem -eq 'Legacy'
}
