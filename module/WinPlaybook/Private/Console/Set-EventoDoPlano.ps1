function Set-EventoDoPlano {
    <#
    .SYNOPSIS
    Aplica ao plano um evento de etapa, como o começo ou o fim dela.

    .DESCRIPTION
    Junta num lugar só o que o Write-ProgressoDoAdministrador e o Invoke-ComoAdministrador
    contam sobre as etapas: inicio chama o Start-ItemDoPlano, fim chama o
    Complete-ItemDoPlano, e remocao chama o Complete-ItemDoPlano com -Remocao. Outro evento
    não muda nada.

    .PARAMETER Plano
    O plano de New-Plano.

    .PARAMETER Evento
    inicio, fim ou remocao.

    .PARAMETER Id
    A etapa do plano.

    .EXAMPLE
    Set-EventoDoPlano -Plano $plano -Evento 'fim' -Id 'localhost.chave'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Plano,
        [Parameter(Mandatory)] [string] $Evento,
        [Parameter(Mandatory)] [string] $Id
    )

    switch ($Evento) {
        'inicio' { Start-ItemDoPlano -Plano $Plano -Id $Id }
        'fim' { Complete-ItemDoPlano -Plano $Plano -Id $Id }
        'remocao' { Complete-ItemDoPlano -Plano $Plano -Id $Id -Remocao }
    }
}
