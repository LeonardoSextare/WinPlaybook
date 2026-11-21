function Get-ValorDoRegistro {
    <#
    .SYNOPSIS
    Devolve um valor do registro do Windows, ou $null quando a chave ou o valor não existem.

    .PARAMETER Chave
    A chave completa, como HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH.

    .PARAMETER Nome
    O nome do valor.

    .EXAMPLE
    Get-ValorDoRegistro -Chave 'HKEY_LOCAL_MACHINE\SOFTWARE\OpenSSH' -Nome 'DefaultShell'

    .LINK
    https://learn.microsoft.com/dotnet/api/microsoft.win32.registry.getvalue
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)] [string] $Chave,
        [Parameter(Mandatory)] [string] $Nome
    )

    return [Microsoft.Win32.Registry]::GetValue($Chave, $Nome, $null)
}
