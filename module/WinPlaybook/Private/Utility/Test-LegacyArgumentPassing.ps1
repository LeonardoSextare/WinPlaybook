function Test-LegacyArgumentPassing {
    <#
    .SYNOPSIS
    Tells whether PowerShell passes arguments to programs without escaping quotes.

    .DESCRIPTION
    Windows PowerShell 5.1 and PowerShell 7.0 to 7.2 always do. PowerShell 7.3 and newer
    escape them, unless $PSNativeCommandArgumentPassing is set to Legacy.

    .EXAMPLE
    Test-LegacyArgumentPassing

    Returns True in Windows PowerShell 5.1.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_preference_variables#psnativecommandargumentpassing
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $hasModernArgumentPassing = $PSVersionTable.PSVersion -ge [version] '7.3'
    if (-not $hasModernArgumentPassing) {
        return $true
    }

    (Get-Variable -Name 'PSNativeCommandArgumentPassing' -ValueOnly -ErrorAction SilentlyContinue) -eq 'Legacy'
}
