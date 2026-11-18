function Get-NivelDoLog {
    <#
    .SYNOPSIS
    Devolve o nível do log do WinPlaybook, pela variável de ambiente WINPLAYBOOK_LOG.

    .DESCRIPTION
    Os níveis são off, que não grava nada, error, só os erros, info, os erros e uma linha
    por comando, com o tempo de cada etapa, e debug, que acrescenta os argumentos, a pasta
    e o tempo de cada preparação na distribuição. Sem a variável, ou com um valor que não é
    um nível, o nível é info. Devolve o nível como número, de 0 (off) a 3 (debug).

    .EXAMPLE
    Get-NivelDoLog

    Devolve 2, o nível info, quando a WINPLAYBOOK_LOG não está definida.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $niveis = @{ off = 0; error = 1; info = 2; debug = 3 }
    $nivelEscolhido = "$env:WINPLAYBOOK_LOG".Trim().ToLowerInvariant()
    $nivelExiste = $niveis.ContainsKey($nivelEscolhido)
    if ($nivelExiste) {
        return $niveis[$nivelEscolhido]
    }

    return $niveis.info
}
