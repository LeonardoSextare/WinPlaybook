function Get-DistribuicaoDoWsl {
    <#
    .SYNOPSIS
    Lista os nomes das distribuições WSL instaladas neste computador.

    .EXAMPLE
    Get-DistribuicaoDoWsl

    Devolve Ubuntu e as outras distribuições que o wsl --list mostra.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $wslEstaInstalado = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $wslEstaInstalado) {
        throw 'O WSL não foi encontrado. O WinPlaybook roda o Ansible numa distribuição WSL: instale o WSL com wsl --install e tente de novo.'
    }

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $listagem = wsl --list --quiet 2>$null
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }

    $listou = $LASTEXITCODE -eq 0
    if (-not $listou) {
        throw 'O WSL não tem distribuições. Instale uma com wsl --install, instale o Ansible nela e tente de novo.'
    }

    return @($listagem | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
}
