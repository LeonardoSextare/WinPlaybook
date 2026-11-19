function Stop-EtapaAtual {
    <#
    .SYNOPSIS
    Para a animação da etapa em andamento e limpa a linha dela, sem escrever um resultado.

    .DESCRIPTION
    Serve para o fim de um comando interrompido, como por um Ctrl+C, que não chega ao
    Complete-Etapa: sem isso, a animação continuaria escrevendo no console. Sem uma etapa em
    andamento, nada muda.

    .EXAMPLE
    Stop-EtapaAtual
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $etapa = Get-Variable -Name 'EtapaAtual' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $script:EtapaAtual = $null
    $temAnimacao = $null -ne $etapa -and $null -ne $etapa.PowerShell
    if (-not $temAnimacao) {
        return
    }

    $etapa.Estado.Rodando = $false
    $null = $etapa.PowerShell.EndInvoke($etapa.Execucao)
    $etapa.PowerShell.Dispose()
    $etapa.PowerShell = $null
    [Console]::Write("`r" + (' ' * ($etapa.Estado.Largura + 6)) + "`r")
}
