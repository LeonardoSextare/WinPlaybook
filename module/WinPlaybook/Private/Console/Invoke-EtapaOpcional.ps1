function Invoke-EtapaOpcional {
    <#
    .SYNOPSIS
    Executa uma etapa que pode falhar sem interromper a instalação, e diz se ela deu certo.

    .DESCRIPTION
    Mostra a etapa como o Start-Etapa e o Complete-Etapa. Se a ação falha, a linha vira [x],
    e abaixo dela aparecem a causa, o comando para tentar de novo e a página de solução de
    problemas. O erro vai para o log, e a instalação continua. Devolve $true quando a ação
    deu certo.

    .PARAMETER Texto
    O que a etapa está fazendo.

    .PARAMETER Resultado
    O texto da linha quando a etapa dá certo.

    .PARAMETER ComandoParaTentarDeNovo
    O comando que refaz a etapa depois, como Enable-WinPlaybookLocalhost.

    .PARAMETER Pagina
    A página da documentação de solução de problemas, como troubleshooting-localhost-windows.

    .PARAMETER Acao
    O que a etapa executa.

    .EXAMPLE
    Invoke-EtapaOpcional -Texto 'Ligando o localhost_windows' -Resultado 'localhost_windows ligado' -ComandoParaTentarDeNovo 'Enable-WinPlaybookLocalhost' -Pagina 'troubleshooting-localhost-windows' -Acao { Enable-WinPlaybookLocalhost -Confirm:$false }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string] $Texto,
        [Parameter(Mandatory)] [string] $Resultado,
        [Parameter(Mandatory)] [string] $ComandoParaTentarDeNovo,
        [Parameter(Mandatory)] [string] $Pagina,
        [Parameter(Mandatory)] [scriptblock] $Acao
    )

    $etapa = Start-Etapa -Texto $Texto
    try {
        & $Acao
    }
    catch {
        $causa = $_.Exception.Message
        Complete-Etapa -Etapa $etapa -Falhou
        Write-Log -Nivel 'error' -Mensagem "$Texto falhou: $causa"
        Write-Host "      $causa" -ForegroundColor Red
        Write-Host "      $(Get-Mensagem -Nome 'TentarDeNovo' -Valores $ComandoParaTentarDeNovo)" -ForegroundColor DarkGray
        Write-Host "      $(Get-Mensagem -Nome 'Ajuda' -Valores (Get-Mensagem -Nome 'PaginaDaDocumentacao' -Valores $Pagina))" -ForegroundColor DarkGray
        return $false
    }
    finally {
        Stop-EtapaAtual
    }

    Complete-Etapa -Etapa $etapa -Resultado $Resultado
    return $true
}
