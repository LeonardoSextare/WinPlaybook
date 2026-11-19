function Get-PacoteDoOpenSsh {
    <#
    .SYNOPSIS
    Devolve a versão do OpenSSH que o localhost_windows usa, com o endereço e o SHA256 do zip dela.

    .DESCRIPTION
    A versão é fixa e testada. O zip é o OpenSSH-Win64 da release oficial da Microsoft, no
    repositório PowerShell/Win32-OpenSSH do GitHub, e o SHA256 é o que o GitHub publica para
    ele. Devolve Versao, Url e Sha256.

    .EXAMPLE
    $pacote = Get-PacoteDoOpenSsh
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $versao = '10.4.0.0p1-Preview'
    return @{
        Versao = $versao
        Url    = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$versao/OpenSSH-Win64.zip"
        Sha256 = 'B67FF8BECD203502190EC42AC7787C24C2CD3325ED7700485FE7A1C83D2A7957'
    }
}
