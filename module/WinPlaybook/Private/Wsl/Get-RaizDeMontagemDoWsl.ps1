function Get-RaizDeMontagemDoWsl {
    <#
    .SYNOPSIS
    Devolve a pasta onde uma distribuição WSL monta as unidades do Windows.

    .DESCRIPTION
    A maioria das distribuições monta a unidade C: em /mnt/c, mas o root do automount, no
    /etc/wsl.conf, pode mudar a pasta.

    .PARAMETER Distribuicao
    A distribuição WSL, como o wsl --list mostra.

    .EXAMPLE
    Get-RaizDeMontagemDoWsl -Distribuicao 'Ubuntu'

    Devolve /mnt/.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao
    )

    $ErrorActionPreference = 'Continue'
    $caminhoDaUnidade = wsl --distribution $Distribuicao --exec wslpath -a 'C:\' 2>$null

    $traduziuAUnidade = ($LASTEXITCODE -eq 0) -and ("$caminhoDaUnidade" -match '^/(.*/)?c/$')
    if (-not $traduziuAUnidade) {
        throw (Get-Mensagem -Nome 'RaizDeMontagemDesconhecida' -Valores $Distribuicao, $LASTEXITCODE)
    }

    return "$caminhoDaUnidade".Substring(0, "$caminhoDaUnidade".Length - 'c/'.Length)
}
