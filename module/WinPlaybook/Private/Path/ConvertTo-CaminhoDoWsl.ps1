function ConvertTo-CaminhoDoWsl {
    <#
    .SYNOPSIS
    Converte um caminho absoluto do Windows para o caminho dele na distribuição WSL.

    .DESCRIPTION
    Um caminho com a letra da unidade fica na pasta da unidade, dentro da raiz de montagem. Um
    caminho de rede (UNC) fica na pasta unc/<servidor>/<compartilhamento> da raiz de
    montagem, onde Mount-PastaDoWindows monta o compartilhamento.

    .PARAMETER Caminho
    O caminho absoluto do Windows, com a letra da unidade ou de rede (\\servidor\compartilhamento).

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .EXAMPLE
    ConvertTo-CaminhoDoWsl -Caminho 'C:\repo\playbooks\site.yml' -RaizDeMontagem '/mnt/'

    Devolve /mnt/c/repo/playbooks/site.yml.

    .EXAMPLE
    ConvertTo-CaminhoDoWsl -Caminho '\\servidor\infra\site.yml' -RaizDeMontagem '/mnt/'

    Devolve /mnt/unc/servidor/infra/site.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Caminho,
        [Parameter(Mandatory)] [string] $RaizDeMontagem
    )

    $raiz = $RaizDeMontagem.TrimEnd('/') + '/'

    $ehCaminhoDeRede = $Caminho -match '^\\\\(?![.?][\\/])[^\\/]+[\\/][^\\/]+'
    if ($ehCaminhoDeRede) {
        return $raiz + 'unc/' + $Caminho.Substring(2).Replace('\', '/').TrimEnd('/')
    }

    $ehCaminhoAbsolutoDoWindows = $Caminho -match '^[A-Za-z]:[\\/]'
    if (-not $ehCaminhoAbsolutoDoWindows) {
        throw (Get-Mensagem -Nome 'CaminhoNaoAbsoluto' -Valores $Caminho)
    }

    $unidade = $Caminho.Substring(0, 1).ToLowerInvariant()
    $caminhoNaUnidade = $Caminho.Substring(2).Replace('\', '/')
    return $raiz + $unidade + $caminhoNaUnidade
}
