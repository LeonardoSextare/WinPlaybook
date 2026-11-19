function Complete-Etapa {
    <#
    .SYNOPSIS
    Termina uma etapa começada pelo Start-Etapa e escreve a linha final dela no console.

    .DESCRIPTION
    Para a animação, se houver, e troca a linha da etapa por [+] em verde com o resultado,
    ou, com -Falhou, por [x] em vermelho com o texto da etapa.

    .PARAMETER Etapa
    O controle devolvido pelo Start-Etapa.

    .PARAMETER Resultado
    O que a etapa entregou, como "Ansible instalado". Sem ele, a linha repete o texto da
    etapa.

    .PARAMETER Falhou
    Marca a etapa como falha.

    .EXAMPLE
    Complete-Etapa -Etapa $etapa -Resultado 'Ansible instalado'

    .EXAMPLE
    Complete-Etapa -Etapa $etapa -Falhou
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Etapa,
        [string] $Resultado,
        [switch] $Falhou
    )

    $script:EtapaAtual = $Etapa
    Stop-EtapaAtual

    if ($Falhou) {
        Write-Log -Nivel 'error' -Mensagem "$($Etapa.Texto) falhou em $($Etapa.Relogio.ElapsedMilliseconds) ms"
        Write-LinhaDaEtapa -Marca '[x]' -Cor 'Red' -Texto $Etapa.Texto
        return
    }

    $texto = $Etapa.Texto
    $temResultado = [bool] $Resultado
    if ($temResultado) {
        $texto = $Resultado
    }
    Write-Log -Nivel 'info' -Mensagem "$($Etapa.Texto) terminou em $($Etapa.Relogio.ElapsedMilliseconds) ms"
    Write-LinhaDaEtapa -Marca '[+]' -Cor 'Green' -Texto $texto
}
