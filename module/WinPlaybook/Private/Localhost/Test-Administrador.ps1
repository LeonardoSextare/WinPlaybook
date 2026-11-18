function Test-Administrador {
    <#
    .SYNOPSIS
    Diz se o PowerShell atual roda como administrador.

    .EXAMPLE
    Test-Administrador

    Devolve $true num PowerShell aberto com "Executar como administrador".
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identidade = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    return $identidade.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
