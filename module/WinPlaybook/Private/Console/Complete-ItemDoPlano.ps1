function Complete-ItemDoPlano {
    <#
    .SYNOPSIS
    Termina uma etapa do plano e troca o sinal dela pelo resultado.

    .DESCRIPTION
    Para a animação e marca a etapa com [+] em verde, [-] em amarelo numa remoção ou [x] em
    vermelho numa falha, e registra no log quanto tempo ela levou. Fora de um terminal
    interativo, a etapa ganha a própria linha agora, depois do título dela, se houver. Sem
    -Id, a função termina a etapa em andamento, se houver.

    .PARAMETER Plano
    O plano de New-Plano.

    .PARAMETER Id
    A etapa que termina. Sem ele, a etapa em andamento.

    .PARAMETER Remocao
    A etapa removeu algo.

    .PARAMETER Falhou
    A etapa falhou.

    .EXAMPLE
    Complete-ItemDoPlano -Plano $plano -Id 'ansible'

    .EXAMPLE
    Complete-ItemDoPlano -Plano $plano -Falhou
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Plano,
        [string] $Id,
        [switch] $Remocao,
        [switch] $Falhou
    )

    $principal = $Plano.Principal
    $temId = [bool] $Id
    if (-not $temId) {
        $Id = $principal.EmAndamento
    }
    $temEtapa = $Id -and $principal.Etapas.Contains($Id)
    if (-not $temEtapa) {
        return
    }

    Stop-AnimacaoDoPlano -Plano $principal
    $etapa = $principal.Etapas[$Id]
    if ($principal.EmAndamento -eq $Id) {
        $principal.EmAndamento = $null
    }

    $milissegundos = 0
    if ($etapa.Relogio) {
        $milissegundos = $etapa.Relogio.ElapsedMilliseconds
    }
    $marca = '+'
    $cor = 'Green'
    if ($Remocao) {
        $marca = '-'
        $cor = 'Yellow'
    }
    if ($Falhou) {
        $marca = 'x'
        $cor = 'Red'
        Write-Log -Nivel 'error' -Mensagem "$($etapa.Texto) falhou em $milissegundos ms"
    }
    else {
        Write-Log -Nivel 'info' -Mensagem "$($etapa.Texto) terminou em $milissegundos ms"
    }

    if ($principal.Interativo) {
        Write-LinhaDoPlano -Etapa $etapa -Marca $marca -Cor $cor -Linha ($principal.PrimeiraLinha + $etapa.Indice)
        return
    }

    $titulo = @($principal.Etapas.Values | Where-Object { $_.Titulo -and $_.Indice -lt $etapa.Indice } | Select-Object -Last 1)
    $mostraOTitulo = $etapa.Recuo -gt 0 -and $titulo.Count -gt 0 -and -not $titulo[0].Mostrou
    if ($mostraOTitulo) {
        Write-LinhaDoPlano -Etapa $titulo[0] -Marca ' ' -Cor 'White'
        $titulo[0].Mostrou = $true
    }
    Write-LinhaDoPlano -Etapa $etapa -Marca $marca -Cor $cor
}
