function Get-PerfilDoPowerShell {
    <#
    .SYNOPSIS
    Devolve os perfis do usuário que valem em todos os hosts do PowerShell 7 e do Windows PowerShell 5.1.

    .DESCRIPTION
    São os profile.ps1 das pastas PowerShell e WindowsPowerShell, dentro de Documentos. Os
    arquivos podem não existir.

    .EXAMPLE
    Get-PerfilDoPowerShell

    Devolve C:\Users\<usuário>\Documents\PowerShell\profile.ps1 e
    C:\Users\<usuário>\Documents\WindowsPowerShell\profile.ps1.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_profiles
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $documentos = [Environment]::GetFolderPath('MyDocuments')
    return @(
        Join-Path -Path $documentos -ChildPath 'PowerShell\profile.ps1'
        Join-Path -Path $documentos -ChildPath 'WindowsPowerShell\profile.ps1'
    )
}
