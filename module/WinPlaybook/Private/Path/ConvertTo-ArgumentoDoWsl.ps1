function ConvertTo-ArgumentoDoWsl {
    <#
    .SYNOPSIS
    Converte um caminho do Windows num argumento de comando para o caminho dele na distribuição WSL.

    .DESCRIPTION
    Um caminho absoluto vira um caminho dentro da pasta onde a distribuição monta as
    unidades. Um caminho relativo com barras invertidas passa a usar barras normais, mas só
    quando ele existe, porque outros argumentos podem ter barras invertidas sem ser
    caminhos. O caminho pode vir depois de uma opção (--inventory=) e depois de @, como em
    -e @vars\prod.yml. Os outros argumentos voltam sem mudança.

    .PARAMETER Argumento
    O argumento, como o usuário passou.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado, para conferir se um caminho relativo existe.

    .EXAMPLE
    ConvertTo-ArgumentoDoWsl -Argumento '.\site.yml' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve ./site.yml.

    .EXAMPLE
    ConvertTo-ArgumentoDoWsl -Argumento '--inventory=C:\repo\hosts.yml' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve --inventory=/mnt/c/repo/hosts.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Argumento,
        [Parameter(Mandatory)] [string] $RaizDeMontagem,
        [Parameter(Mandatory)] [string] $PastaAtual
    )

    $null = $Argumento -match '^(?<prefixo>(--[\w-]+=)?@?)(?<valor>.*)$'
    $prefixo = $Matches.prefixo
    $valor = $Matches.valor

    $ehCaminhoAbsolutoDoWindows = $valor -match '^[A-Za-z]:[\\/]'
    if ($ehCaminhoAbsolutoDoWindows) {
        return $prefixo + (ConvertTo-CaminhoDoWsl -Caminho $valor -RaizDeMontagem $RaizDeMontagem)
    }

    $ehCaminhoRelativoExistente = $valor.Contains('\') -and (Test-Path -LiteralPath (Join-Path -Path $PastaAtual -ChildPath $valor))
    if ($ehCaminhoRelativoExistente) {
        return $prefixo + $valor.Replace('\', '/')
    }

    return $Argumento
}
