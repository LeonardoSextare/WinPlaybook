function Stop-AnimacaoDoPlano {
    <#
    .SYNOPSIS
    Para a animação da etapa em andamento do plano, sem mudar o sinal dela.

    .DESCRIPTION
    Espera a thread da animação parar e libera o runspace. Sem animação, nada muda.

    .PARAMETER Plano
    O plano de New-Plano.

    .EXAMPLE
    Stop-AnimacaoDoPlano -Plano $plano
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Plano
    )

    $animacao = $Plano.Principal.Animacao
    $temAnimacao = $null -ne $animacao
    if (-not $temAnimacao) {
        return
    }

    $animacao.Estado.Rodando = $false
    $null = $animacao.PowerShell.EndInvoke($animacao.Execucao)
    $animacao.PowerShell.Dispose()
    $Plano.Principal.Animacao = $null
}
