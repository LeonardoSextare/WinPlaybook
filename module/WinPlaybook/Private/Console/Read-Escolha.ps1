function Read-Escolha {
    <#
    .SYNOPSIS
    Faz ao usuário uma pergunta de sim ou não, com a opção recomendada como padrão, e devolve $true para sim.

    .DESCRIPTION
    Mostra a pergunta com a marca de recomendado, a explicação e o link da documentação, e
    depois o prompt no formato dos comandos do PowerShell, como [S] Sim  [N] Não  [?] Ajuda
    (o padrão é "S"), sempre no idioma do WinPlaybook. O Enter escolhe sim, e o ? mostra o que
    cada opção faz e pergunta de novo.

    .PARAMETER Pergunta
    A pergunta, como "Ativar o localhost_windows?".

    .PARAMETER Explicacao
    Uma ou duas frases curtas sobre o que a escolha faz.

    .PARAMETER Link
    A página da documentação sobre o assunto.

    .PARAMETER AjudaDoSim
    O que acontece com sim, mostrado no ?.

    .PARAMETER AjudaDoNao
    O que acontece com não, mostrado no ?.

    .EXAMPLE
    Read-Escolha -Pergunta 'Ativar o localhost_windows?' -Explicacao '...' -Link 'https://...' -AjudaDoSim '...' -AjudaDoNao '...'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string] $Pergunta,
        [Parameter(Mandatory)] [string] $Explicacao,
        [Parameter(Mandatory)] [string] $Link,
        [Parameter(Mandatory)] [string] $AjudaDoSim,
        [Parameter(Mandatory)] [string] $AjudaDoNao
    )

    $teclaDoSim = Get-Mensagem -Nome 'TeclaDoSim'
    $teclaDoNao = Get-Mensagem -Nome 'TeclaDoNao'

    Write-Host ''
    Write-Host $Pergunta -ForegroundColor White -NoNewline
    Write-Host " $(Get-Mensagem -Nome 'Recomendado')" -ForegroundColor Green
    Write-Host $Explicacao -ForegroundColor DarkGray
    Write-Host (Get-Mensagem -Nome 'SaibaMais' -Valores $Link) -ForegroundColor DarkGray
    while ($true) {
        Write-Host "[$teclaDoSim] $(Get-Mensagem -Nome 'OpcaoSim')  " -ForegroundColor Yellow -NoNewline
        Write-Host "[$teclaDoNao] $(Get-Mensagem -Nome 'OpcaoNao')  $(Get-Mensagem -Nome 'PromptDaEscolha' -Valores $teclaDoSim)" -NoNewline
        $resposta = "$(Read-Host)".Trim()
        $escolheuSim = $resposta -eq '' -or $resposta -eq $teclaDoSim
        if ($escolheuSim) {
            return $true
        }
        $escolheuNao = $resposta -eq $teclaDoNao
        if ($escolheuNao) {
            return $false
        }
        $pediuAjuda = $resposta -eq '?'
        if ($pediuAjuda) {
            Write-Host "$teclaDoSim - $AjudaDoSim"
            Write-Host "$teclaDoNao - $AjudaDoNao"
        }
    }
}
