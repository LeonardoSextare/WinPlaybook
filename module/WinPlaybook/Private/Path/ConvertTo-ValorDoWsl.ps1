function ConvertTo-ValorDoWsl {
    <#
    .SYNOPSIS
    Converte os caminhos do Windows no valor de uma variável de ambiente para os caminhos deles na distribuição WSL.

    .DESCRIPTION
    O valor pode ser um caminho ou uma lista de caminhos. Uma lista separada por ponto e
    vírgula, como as do Windows, vira uma lista separada por dois-pontos, como as do Linux,
    quando tem algum caminho do Windows. Uma lista separada por vírgula, como a do
    ANSIBLE_INVENTORY, continua com vírgulas. Cada caminho segue as regras do
    ConvertTo-ArgumentoDoWsl, e um valor sem caminhos do Windows volta sem mudança.

    .PARAMETER Valor
    O valor da variável, como o usuário definiu no Windows.

    .PARAMETER Distribuicao
    A distribuição WSL onde o comando roda, como o wsl --list mostra.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado, para os caminhos relativos.

    .PARAMETER DestinoDeUnidade
    A pasta real das unidades do subst e de rede, como Get-DestinoDeUnidade devolve. Um
    caminho numa dessas unidades vira o caminho da pasta real.

    .EXAMPLE
    ConvertTo-ValorDoWsl -Valor 'C:\roles;D:\roles' -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve /mnt/c/roles:/mnt/d/roles.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Valor,
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $RaizDeMontagem,
        [Parameter(Mandatory)] [string] $PastaAtual,
        [hashtable] $DestinoDeUnidade = @{}
    )

    $parametrosDaConversao = @{ Distribuicao = $Distribuicao; RaizDeMontagem = $RaizDeMontagem; PastaAtual = $PastaAtual; DestinoDeUnidade = $DestinoDeUnidade }

    $itensDaListaDoWindows = $Valor.Split(';')
    $ehListaDoWindows = $itensDaListaDoWindows.Count -gt 1
    if ($ehListaDoWindows) {
        $itensConvertidos = @(foreach ($item in $itensDaListaDoWindows) { ConvertTo-ArgumentoDoWsl -Argumento $item @parametrosDaConversao })
        $temCaminhoDoWindows = ($itensConvertidos -join ';') -cne $Valor
        if ($temCaminhoDoWindows) {
            return $itensConvertidos -join ':'
        }

        return $Valor
    }

    $itensConvertidos = @(foreach ($item in $Valor.Split(',')) { ConvertTo-ArgumentoDoWsl -Argumento $item @parametrosDaConversao })
    return $itensConvertidos -join ','
}
