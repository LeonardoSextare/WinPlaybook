function ConvertTo-CaminhoDoWsl {
    <#
    .SYNOPSIS
    Converte um caminho absoluto do Windows para o caminho dele na distribuição WSL.

    .PARAMETER Caminho
    O caminho absoluto do Windows, com a letra da unidade.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .EXAMPLE
    ConvertTo-CaminhoDoWsl -Caminho 'C:\repo\playbooks\site.yml' -RaizDeMontagem '/mnt/'

    Devolve /mnt/c/repo/playbooks/site.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Caminho,
        [Parameter(Mandatory)] [string] $RaizDeMontagem
    )

    $ehCaminhoAbsolutoDoWindows = $Caminho -match '^[A-Za-z]:[\\/]'
    if (-not $ehCaminhoAbsolutoDoWindows) {
        throw (Get-Mensagem -Nome 'CaminhoNaoAbsoluto' -Valores $Caminho)
    }

    $unidade = $Caminho.Substring(0, 1).ToLowerInvariant()
    $caminhoNaUnidade = $Caminho.Substring(2).Replace('\', '/')
    return $RaizDeMontagem.TrimEnd('/') + '/' + $unidade + $caminhoNaUnidade
}
