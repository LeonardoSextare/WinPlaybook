function Test-WslInstalado {
    <#
    .SYNOPSIS
    Diz se o WSL está instalado e pronto para criar distribuições.

    .DESCRIPTION
    O wsl.exe existe no Windows mesmo antes da instalação do WSL, porque é ele que roda o
    wsl --install. Por isso a resposta vem do wsl --status, que falha enquanto o WSL não
    está instalado.

    .EXAMPLE
    Test-WslInstalado

    Devolve True num Windows com o WSL instalado.

    .LINK
    https://learn.microsoft.com/windows/wsl/basic-commands#check-wsl-status
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $temWslExe = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $temWslExe) {
        return $false
    }

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $null = wsl --status 2>&1
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }

    return $LASTEXITCODE -eq 0
}
