function Close-Plano {
    <#
    .SYNOPSIS
    Fecha o plano: marca como falha a etapa que ficou em andamento e libera o console.

    .DESCRIPTION
    Serve para o fim de um comando, inclusive quando ele falha ou é interrompido por um
    Ctrl+C: a etapa em andamento vira [x], a animação para e o próximo plano pode começar. As
    etapas que não começaram ficam com [ ]. O plano de dentro de outro não fecha nada.

    .PARAMETER Plano
    O plano de New-Plano.

    .EXAMPLE
    Close-Plano -Plano $plano
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Plano
    )

    if ($Plano.Aninhado) {
        return
    }

    $ficouEtapaEmAndamento = [bool] $Plano.EmAndamento
    if ($ficouEtapaEmAndamento) {
        Complete-ItemDoPlano -Plano $Plano -Falhou
    }
    Stop-AnimacaoDoPlano -Plano $Plano
    $script:Plano = $null
}
