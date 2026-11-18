function ConvertTo-ArgumentoDoWsl {
    <#
    .SYNOPSIS
    Converte um caminho do Windows num argumento de comando para o caminho dele na distribuição WSL.

    .DESCRIPTION
    Um caminho absoluto, com a letra da unidade ou de rede (\\servidor\compartilhamento),
    vira um caminho dentro da pasta onde a distribuição monta as unidades, como
    ConvertTo-CaminhoDoWsl faz. Um caminho do disco do Linux da distribuição, como
    \\wsl.localhost\Ubuntu\home\eu\site.yml, vira o caminho dele no Linux. Um caminho
    relativo com barras invertidas passa a usar barras normais quando começa com .\ ou ..\,
    ou quando a pasta dele existe, mesmo que o arquivo ainda não exista, porque outros
    argumentos podem ter barras invertidas sem ser caminhos. O caminho pode vir depois de
    uma opção (--inventory=) e depois de @, como em -e @vars\prod.yml. Um caminho absoluto
    também vira o da distribuição como valor de um chave=valor, como os do -e e do -a
    (-e pasta=C:\infra\files, -a "path=C:\infra\site.yml mode=0644"). Um caminho do Windows
    no formato de uma URI, com uma barra antes da unidade (/C:/infra/site.yml), como o
    passam programas que convertem URIs, como a extensão Ansible do VS Code, é tratado
    como C:/infra/site.yml. Os outros argumentos
    voltam sem mudança.

    .PARAMETER Argumento
    O argumento, como o usuário passou.

    .PARAMETER Distribuicao
    A distribuição WSL onde o comando roda, como o wsl --list mostra.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado, para conferir se a pasta de um caminho relativo existe.

    .PARAMETER DestinoDeUnidade
    A pasta real das unidades do subst e de rede, como Get-DestinoDeUnidade devolve. Um
    caminho numa dessas unidades vira o caminho da pasta real.

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
        [Parameter(Mandatory)] [string] $PastaAtual,
        [hashtable] $DestinoDeUnidade = @{}
    )

    $null = $Argumento -match '^(?<prefixo>(--[\w-]+=)?@?)(?<valor>.*)$'
    $prefixo = $Matches.prefixo
    $valor = $Matches.valor
    $valor = $valor -replace '^/(?=[A-Za-z]:[\\/])', ''

    $ehCaminhoAbsolutoDoWindows = $valor -match '^[A-Za-z]:[\\/]'
    if ($ehCaminhoAbsolutoDoWindows) {
        $unidade = $valor.Substring(0, 1).ToUpperInvariant()
        $caminhoReal = $valor
        $unidadeApontaParaOutraPasta = $DestinoDeUnidade.ContainsKey($unidade)
        if ($unidadeApontaParaOutraPasta) {
            $caminhoReal = $DestinoDeUnidade[$unidade].TrimEnd('\') + '\' + $valor.Substring(3)
        }
        return $prefixo + (ConvertTo-CaminhoDoWsl -Caminho $caminhoReal -RaizDeMontagem $RaizDeMontagem)
    }

    foreach ($raizDaDistribuicao in ('\\wsl.localhost\' + $Distribuicao + '\'), ('\\wsl$\' + $Distribuicao + '\')) {
        $ehCaminhoDoDiscoDoLinux = $valor.StartsWith($raizDaDistribuicao, [StringComparison]::OrdinalIgnoreCase)
        if ($ehCaminhoDoDiscoDoLinux) {
            return $prefixo + '/' + $valor.Substring($raizDaDistribuicao.Length).Replace('\', '/')
        }
    }

    $ehCaminhoDeRede = ($valor -match '^\\\\(?<servidor>[^\\/]+)[\\/][^\\/]+') -and ($Matches.servidor -notin 'wsl.localhost', 'wsl$', '.', '?')
    if ($ehCaminhoDeRede) {
        return $prefixo + (ConvertTo-CaminhoDoWsl -Caminho $valor -RaizDeMontagem $RaizDeMontagem)
    }

    $padraoDeCaminhoNumValor = '(?<=(^|\s)[\w.-]+=)[A-Za-z]:[\\/]\S*'
    $temCaminhoNumValor = $Argumento -match $padraoDeCaminhoNumValor
    if ($temCaminhoNumValor) {
        $parametrosDaConversao = @{ Distribuicao = $Distribuicao; RaizDeMontagem = $RaizDeMontagem; PastaAtual = $PastaAtual; DestinoDeUnidade = $DestinoDeUnidade }
        return [regex]::Replace($Argumento, $padraoDeCaminhoNumValor, { param($ocorrencia) ConvertTo-ArgumentoDoWsl -Argumento $ocorrencia.Value @parametrosDaConversao })
    }

    $ehCaminhoRelativoDoWindows = Test-CaminhoRelativoDoWindows -Caminho $valor -PastaAtual $PastaAtual
    if ($ehCaminhoRelativoDoWindows) {
        return $prefixo + $valor.Replace('\', '/')
    }

    return $Argumento
}
