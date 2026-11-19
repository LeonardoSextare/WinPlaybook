function Write-FalhaDaEtapa {
    <#
    .SYNOPSIS
    Escreve, abaixo do plano, a causa de uma etapa que falhou sem interromper o comando, o comando para tentar de novo e a página de ajuda.

    .DESCRIPTION
    Fica fora do plano, depois do Close-Plano, para não deslocar as linhas que o plano
    atualiza no lugar.

    .PARAMETER Causa
    A mensagem do erro.

    .PARAMETER Comando
    O comando que refaz a etapa, como Enable-WinPlaybookLocalhost.

    .PARAMETER Pagina
    A página da documentação de solução de problemas, como troubleshooting-localhost-windows.

    .EXAMPLE
    Write-FalhaDaEtapa -Causa 'sem permissão' -Comando 'Enable-WinPlaybookLocalhost' -Pagina 'troubleshooting-localhost-windows'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Causa,
        [Parameter(Mandatory)] [string] $Comando,
        [Parameter(Mandatory)] [string] $Pagina
    )

    Write-Log -Nivel 'error' -Mensagem "$Comando falhou: $Causa"
    Write-Host ''
    Write-Host $Causa -ForegroundColor Red
    Write-Host "$((Get-Mensagem -Nome 'TentarDeNovo' -Valores '').TrimEnd()) " -ForegroundColor DarkGray -NoNewline
    Write-Host $Comando -ForegroundColor Cyan
    Write-Host (Get-Mensagem -Nome 'Ajuda' -Valores (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores $Pagina)) -ForegroundColor DarkGray
}
