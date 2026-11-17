function Get-UnidadeFixa {
    <#
    .SYNOPSIS
    Lista as letras das unidades fixas do Windows.

    .DESCRIPTION
    São as unidades que o WSL monta sozinho na distribuição, como C e D. Devolve as letras em
    minúscula, sem os dois-pontos.

    .EXAMPLE
    Get-UnidadeFixa

    Devolve c e d.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @([IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq [IO.DriveType]::Fixed } | ForEach-Object { $_.Name.Substring(0, 1).ToLowerInvariant() })
}
