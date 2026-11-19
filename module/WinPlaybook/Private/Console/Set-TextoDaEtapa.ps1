function Set-TextoDaEtapa {
    <#
    .SYNOPSIS
    Troca o texto da etapa em andamento, para mostrar a parte dela que está rodando.

    .DESCRIPTION
    Sem uma etapa em andamento, nada muda. O texto novo aparece no próximo quadro da
    animação, e o Complete-Etapa limpa a linha inteira, mesmo que um texto tenha sido maior
    que o outro.

    .PARAMETER Texto
    O texto novo, como "Instalando o OpenSSH Server".

    .EXAMPLE
    Set-TextoDaEtapa -Texto 'Instalando o OpenSSH Server'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Texto
    )

    $etapa = Get-Variable -Name 'EtapaAtual' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $temEtapa = $null -ne $etapa
    if (-not $temEtapa) {
        return
    }

    $estado = $etapa.Estado
    $estado.Largura = [Math]::Max($estado.Largura, $Texto.Length)
    $estado.Texto = $Texto
}
