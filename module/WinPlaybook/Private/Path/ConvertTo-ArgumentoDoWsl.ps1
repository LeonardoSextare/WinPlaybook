function ConvertTo-ArgumentoDoWsl {
    <#
    .SYNOPSIS
    Converte um caminho do Windows num argumento de comando para o caminho dele na distribuição WSL.

    .DESCRIPTION
    Um caminho absoluto vira um caminho dentro da pasta onde a distribuição monta as
    unidades. Um caminho do disco do Linux da distribuição, como
    \\wsl.localhost\Ubuntu\home\eu\site.yml, vira o caminho dele no Linux. Um caminho
    relativo com barras invertidas passa a usar barras normais quando começa com .\ ou ..\,
    ou quando a pasta dele existe, mesmo que o arquivo ainda não exista, porque outros
    argumentos podem ter barras invertidas sem ser caminhos. O caminho pode vir depois de
    uma opção (--inventory=) e depois de @, como em -e @vars\prod.yml. Os outros argumentos
    voltam sem mudança.

    .PARAMETER Argumento
    O argumento, como o usuário passou.

    .PARAMETER Distribuicao
    A distribuição WSL onde o comando roda, como o wsl --list mostra.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado, para conferir se a pasta de um caminho relativo existe.

    .EXAMPLE
    ConvertTo-ArgumentoDoWsl -Argumento '.\site.yml' -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve ./site.yml.

    .EXAMPLE
    ConvertTo-ArgumentoDoWsl -Argumento '--inventory=C:\repo\hosts.yml' -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve --inventory=/mnt/c/repo/hosts.yml.

    .EXAMPLE
    ConvertTo-ArgumentoDoWsl -Argumento '\\wsl.localhost\Ubuntu\home\eu\site.yml' -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve /home/eu/site.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Argumento,
        [Parameter(Mandatory)] [string] $Distribuicao,
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

    foreach ($raizDaDistribuicao in ('\\wsl.localhost\' + $Distribuicao + '\'), ('\\wsl$\' + $Distribuicao + '\')) {
        $ehCaminhoDoDiscoDoLinux = $valor.StartsWith($raizDaDistribuicao, [StringComparison]::OrdinalIgnoreCase)
        if ($ehCaminhoDoDiscoDoLinux) {
            return $prefixo + '/' + $valor.Substring($raizDaDistribuicao.Length).Replace('\', '/')
        }
    }

    $ehCaminhoRelativoDoWindows = Test-CaminhoRelativoDoWindows -Caminho $valor -PastaAtual $PastaAtual
    if ($ehCaminhoRelativoDoWindows) {
        return $prefixo + $valor.Replace('\', '/')
    }

    return $Argumento
}
