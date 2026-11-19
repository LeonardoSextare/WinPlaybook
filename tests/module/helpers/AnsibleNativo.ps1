function Copy-ProjetoParaDistribuicao {
    <#
    .SYNOPSIS
    Copia um projeto do Windows para o disco do Linux da distribuição e devolve o caminho dele lá.

    .DESCRIPTION
    A cópia fica numa pasta nova em /tmp, com as permissões de um projeto criado no Linux:
    755 nas pastas e 644 nos arquivos.

    .PARAMETER Distribuicao
    A distribuição WSL que recebe a cópia.

    .PARAMETER Origem
    A pasta do projeto no Windows.

    .EXAMPLE
    $projetoNoLinux = Copy-ProjetoParaDistribuicao -Distribuicao $nomeDaDistribuicao -Origem $projeto
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Origem
    )

    $pastaNoLinux = "/tmp/winplaybook-teste-$([guid]::NewGuid().ToString('N'))"
    $script = 'mkdir -p "$1" && cp -R --no-preserve=mode "$(wslpath -a "$0")/." "$1"'
    $argumentosDoWsl = @('--distribution', $Distribuicao, '--exec', 'sh', '-c', $script, $Origem, $pastaNoLinux)

    $resultado = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos $argumentosDoWsl)
    if ($resultado.CodigoDeSaida -ne 0) {
        throw "Não foi possível copiar $Origem para a distribuição WSL ${Distribuicao}: $($resultado.Erro)"
    }

    return $pastaNoLinux
}

function Remove-PastaDaDistribuicao {
    <#
    .SYNOPSIS
    Apaga uma pasta criada pelo Copy-ProjetoParaDistribuicao no disco do Linux da distribuição.

    .DESCRIPTION
    Recusa pastas fora de /tmp/winplaybook-teste-, para nunca apagar outra pasta da distribuição.

    .PARAMETER Distribuicao
    A distribuição WSL onde a pasta está.

    .PARAMETER Pasta
    A pasta no disco do Linux.

    .EXAMPLE
    Remove-PastaDaDistribuicao -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Pasta
    )

    $ehPastaDeTeste = $Pasta.StartsWith('/tmp/winplaybook-teste-', [StringComparison]::Ordinal)
    if (-not $ehPastaDeTeste) {
        throw "A pasta $Pasta não foi criada pelo Copy-ProjetoParaDistribuicao."
    }

    $argumentosDoWsl = @('--distribution', $Distribuicao, '--exec', 'rm', '-rf', '--', $Pasta)
    $null = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos $argumentosDoWsl)
}

function ConvertTo-CaminhoNaDistribuicao {
    <#
    .SYNOPSIS
    Devolve o caminho que a distribuição usa para um caminho do Windows, segundo o wslpath dela.

    .PARAMETER Distribuicao
    A distribuição WSL.

    .PARAMETER Caminho
    O caminho absoluto do Windows.

    .EXAMPLE
    ConvertTo-CaminhoNaDistribuicao -Distribuicao $nomeDaDistribuicao -Caminho 'C:\repo'

    Devolve /mnt/c/repo.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Caminho
    )

    $argumentosDoWsl = @('--distribution', $Distribuicao, '--exec', 'wslpath', '-a', $Caminho)
    $resultado = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos $argumentosDoWsl)
    if ($resultado.CodigoDeSaida -ne 0) {
        throw "Não foi possível converter $Caminho na distribuição WSL ${Distribuicao}: $($resultado.Erro)"
    }

    return $resultado.Saida
}

function Get-ArquivoDoProjeto {
    <#
    .SYNOPSIS
    Lista os arquivos de uma pasta como o Linux da distribuição os vê, com os caminhos relativos a ela.

    .DESCRIPTION
    Os caminhos vêm em ordem e no formato do find, como ./playbooks/site.yml.

    .PARAMETER Distribuicao
    A distribuição WSL.

    .PARAMETER Pasta
    A pasta, como caminho do Windows ou do disco do Linux.

    .EXAMPLE
    Get-ArquivoDoProjeto -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Pasta
    )

    $argumentosDoWsl = @('--distribution', $Distribuicao, '--cd', $Pasta, '--exec', 'sh', '-c', 'find . -type f | LC_ALL=C sort')
    $resultado = Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos $argumentosDoWsl)
    if ($resultado.CodigoDeSaida -ne 0) {
        throw "Não foi possível listar os arquivos de $Pasta na distribuição WSL ${Distribuicao}: $($resultado.Erro)"
    }

    return @($resultado.Saida -split '\r?\n' | Where-Object { $_ })
}

function Invoke-AnsibleNativo {
    <#
    .SYNOPSIS
    Executa um comando direto no Linux da distribuição e devolve o código de saída, a saída e os erros.

    .DESCRIPTION
    É a referência do que o WinPlaybook entrega no Windows: o comando roda num login shell,
    a partir de uma pasta do disco do Linux, e recebe os argumentos sem que um shell os
    interprete. Devolve um objeto com CodigoDeSaida, Saida e Erro.

    .PARAMETER Distribuicao
    A distribuição WSL.

    .PARAMETER Pasta
    A pasta do disco do Linux de onde o comando é executado.

    .PARAMETER Comando
    O comando, como ansible-playbook.

    .PARAMETER Argumentos
    Os argumentos do comando, no formato do Linux.

    .PARAMETER CaminhoDaEntrada
    Um arquivo do Windows que o comando recebe na entrada padrão, como em cat arquivo | comando.

    .PARAMETER Variaveis
    As variáveis de ambiente que o comando recebe, como as que o usuário exporta no shell.

    .EXAMPLE
    Invoke-AnsibleNativo -Distribuicao $nomeDaDistribuicao -Pasta $projetoNoLinux -Comando 'ansible-playbook' -Argumentos 'site.yml'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $Pasta,
        [Parameter(Mandatory)] [string] $Comando,
        [AllowEmptyString()] [string[]] $Argumentos = @(),
        [string] $CaminhoDaEntrada,
        [hashtable] $Variaveis = @{}
    )

    $atribuicoes = @($Variaveis.Keys | Sort-Object | ForEach-Object { "$_=$($Variaveis[$_])" })
    $argumentosDoWsl = @('--distribution', $Distribuicao, '--cd', $Pasta, '--exec', 'sh', '-lc', 'exec env "$@"', 'sh') + $atribuicoes + @($Comando) + $Argumentos
    if ($CaminhoDaEntrada) {
        $entradaNaDistribuicao = ConvertTo-CaminhoNaDistribuicao -Distribuicao $Distribuicao -Caminho $CaminhoDaEntrada
        $argumentosDoWsl = @('--distribution', $Distribuicao, '--cd', $Pasta, '--exec', 'sh', '-lc', 'entrada="$1"; shift; cat "$entrada" | env "$@"', 'sh', $entradaNaDistribuicao) + $atribuicoes + @($Comando) + $Argumentos
    }

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        return Invoke-LinhaDeComando -Programa 'wsl.exe' -Argumentos (ConvertTo-LinhaDeComando -Argumentos $argumentosDoWsl)
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }
}

function Format-SaidaDoAnsible {
    <#
    .SYNOPSIS
    Troca as pastas do projeto por <projeto> e as quebras de linha do Windows pelas do Linux.

    .DESCRIPTION
    Deixa comparáveis as saídas de um mesmo projeto copiado para pastas diferentes. As barras
    invertidas, simples ou escapadas, viram barras normais, para os caminhos do Windows que o
    WinPlaybook mostra se compararem com os do Linux.

    .PARAMETER Texto
    A saída ou os erros de um comando.

    .PARAMETER PastasDoProjeto
    Os caminhos do projeto que aparecem no texto, como o Linux os mostra.

    .EXAMPLE
    Format-SaidaDoAnsible -Texto $resultado.Saida -PastasDoProjeto $projetoNoLinux
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Texto,
        [Parameter(Mandatory)] [string[]] $PastasDoProjeto
    )

    $textoFormatado = $Texto.Replace("`r`n", "`n").Replace('\\\\wsl.localhost', '//wsl.localhost').Replace('\\wsl.localhost', '//wsl.localhost').Replace('\\', '/').Replace('\', '/')
    foreach ($pasta in $PastasDoProjeto) {
        $textoFormatado = $textoFormatado.Replace($pasta, '<projeto>')
    }

    return $textoFormatado
}

function ConvertTo-SaidaVistaDoWindows {
    <#
    .SYNOPSIS
    Troca, na saída de um comando do nó de controle no Linux, os caminhos da distribuição pelos que o WinPlaybook mostra.

    .DESCRIPTION
    Um caminho da distribuição vira //wsl.localhost/<distribuição>/..., e as pastas
    .ansible\collections, .ansible\roles e .ansible\plugins e o .ansible.cfg, que a distribuição
    liga ao perfil do Windows, viram os caminhos delas no perfil. Uma lista de caminhos passa a
    ser separada por ponto e vírgula. As barras ficam normais, porque o Format-SaidaDoAnsible
    deixa as duas saídas com barras normais antes de compará-las. É o que o WinPlaybook
    mostra no ansible-config, no ansible-doc, no ansible-galaxy e no ansible --version.

    .PARAMETER Texto
    A saída ou os erros do comando no Linux.

    .PARAMETER Distribuicao
    A distribuição WSL em que o comando rodou.

    .PARAMETER PastaDoPerfil
    A pasta do perfil do Windows que a distribuição usa.

    .EXAMPLE
    ConvertTo-SaidaVistaDoWindows -Texto $saida -Distribuicao 'WinPlaybookE2E' -PastaDoPerfil $pastaDoPerfil
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Texto,
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $PastaDoPerfil
    )

    $perfil = $PastaDoPerfil.Replace('\', '/')
    $ligacoesParaOPerfil = [ordered]@{
        '/home/winplaybook/.ansible/collections' = "$perfil/.ansible/collections"
        '/home/winplaybook/.ansible/roles'       = "$perfil/.ansible/roles"
        '/home/winplaybook/.ansible/plugins'     = "$perfil/.ansible/plugins"
        '/home/winplaybook/.ansible.cfg'         = "$perfil/.ansible.cfg"
    }
    $padrao = '(?<![\w/.~-])/(?:home|root|tmp|usr|etc|opt|var|srv)(?:/[^\s''"\],:;=()]*)?'
    $Texto = [regex]::Replace($Texto, '(?<![\w/.~-])/[^\s''"\],:;=()]*(?::/[^\s''"\],:;=()]*)+', {
            param($lista)
            $todosSaoTraduzidos = @($lista.Value.Split(':') | Where-Object { $_ -notmatch '^/(?:home|root|tmp|usr|etc|opt|var|srv|mnt/[a-z])(?:/|$)' }).Count -eq 0
            if ($todosSaoTraduzidos) {
                return $lista.Value.Replace(':/', ';/')
            }
            return $lista.Value
        })
    return [regex]::Replace($Texto, $padrao, {
            param($ocorrencia)
            foreach ($ligacao in $ligacoesParaOPerfil.Keys) {
                $estaNoPerfil = $ocorrencia.Value -eq $ligacao -or $ocorrencia.Value.StartsWith("$ligacao/")
                if ($estaNoPerfil) {
                    return $ligacoesParaOPerfil[$ligacao] + $ocorrencia.Value.Substring($ligacao.Length)
                }
            }
            return "//wsl.localhost/$Distribuicao" + $ocorrencia.Value
        })
}
