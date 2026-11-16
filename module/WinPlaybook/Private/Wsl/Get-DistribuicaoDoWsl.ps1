function Get-DistribuicaoDoWsl {
    <#
    .SYNOPSIS
    Lista os nomes das distribuições WSL instaladas neste computador.

    .DESCRIPTION
    Devolve uma lista vazia quando o WSL não tem distribuições, porque nesse caso o
    wsl --list falha.

    .EXAMPLE
    Get-DistribuicaoDoWsl

    Devolve WinPlaybook e as outras distribuições que o wsl --list mostra.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $wslEstaInstalado = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $wslEstaInstalado) {
        throw (Get-Mensagem -Nome 'WslNaoEncontrado')
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
        return @()
    }

    return @($listagem | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
}
