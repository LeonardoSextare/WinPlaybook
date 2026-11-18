function Initialize-LocalhostWindows {
    <#
    .SYNOPSIS
    Na instalação, liga o localhost_windows ou oferece ao usuário ligá-lo.

    .DESCRIPTION
    Com Ligar, chama o Enable-WinPlaybookLocalhost sem perguntar. Sem ele, num terminal
    interativo, pergunta se o usuário quer ligar o localhost_windows, que pede
    administrador. Uma recusa fica guardada, e as próximas instalações não perguntam de
    novo; o Enable-WinPlaybookLocalhost liga depois. Quando o usuário aceita e a ligação
    falha, como numa elevação recusada, a instalação continua e avisa como ligar depois.
    Com o localhost_windows já ligado, nada muda.

    .PARAMETER Configuracao
    A configuração de antes da instalação, de Get-Configuracao.

    .PARAMETER Ligar
    Liga sem perguntar, como o -EnableLocalhost do Install-WinPlaybook.

    .EXAMPLE
    Initialize-LocalhostWindows -Configuracao $configuracao
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Configuracao,
        [switch] $Ligar
    )

    $jaEstaLigado = [bool] $Configuracao['LocalhostWindowsPort']
    if ($jaEstaLigado) {
        return
    }

    if ($Ligar) {
        Enable-WinPlaybookLocalhost -Confirm:$false
        return
    }

    $naoDevePerguntar = [bool] $Configuracao['LocalhostWindowsDeclined'] -or -not (Test-SessaoInterativa)
    if ($naoDevePerguntar) {
        return
    }

    $aceitou = Read-EscolhaDoLocalhostWindows
    if (-not $aceitou) {
        $configuracaoAtual = Get-Configuracao
        $configuracaoAtual['LocalhostWindowsDeclined'] = $true
        Save-Configuracao -Configuracao $configuracaoAtual
        return
    }

    try {
        Enable-WinPlaybookLocalhost -Confirm:$false
    }
    catch {
        Write-Warning (Get-Mensagem -Nome 'LocalhostWindowsNaoLigado' -Valores $_.Exception.Message)
    }
}
