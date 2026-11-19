function Write-LinhaDoPlano {
    <#
    .SYNOPSIS
    Escreve no console a linha de uma etapa do plano, com o sinal dela.

    .DESCRIPTION
    O texto vem recuado conforme a etapa. Um título aparece em branco e sem sinal; as outras
    etapas aparecem com o sinal entre colchetes, na cor pedida, e o texto em cinza enquanto a
    etapa não começou. Com -Linha, a função escreve por cima daquela linha do console e volta
    o cursor para onde ele estava; sem ela, escreve uma linha nova.

    .PARAMETER Etapa
    A etapa do plano.

    .PARAMETER Marca
    O sinal, como +, -, x, um quadro da animação ou um espaço para a etapa que não começou.

    .PARAMETER Cor
    A cor do sinal.

    .PARAMETER Linha
    A linha do console em que a etapa está, para atualizá-la no lugar.

    .EXAMPLE
    Write-LinhaDoPlano -Etapa $etapa -Marca '+' -Cor 'Green' -Linha 12
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [hashtable] $Etapa,
        [Parameter(Mandatory)] [string] $Marca,
        [Parameter(Mandatory)] [ConsoleColor] $Cor,
        [int] $Linha = -1
    )

    $atualizaNoLugar = $Linha -ge 0
    if ($atualizaNoLugar) {
        $linhaDeVolta = [Console]::CursorTop
        [Console]::SetCursorPosition(0, $Linha)
    }

    $recuo = '  ' + ('    ' * $Etapa.Recuo)
    if ($Etapa.Titulo) {
        Write-Host "$recuo$($Etapa.Texto)" -ForegroundColor White -NoNewline:$atualizaNoLugar
    }
    else {
        $corDoTexto = 'Gray'
        $naoComecou = $Marca -eq ' '
        if ($naoComecou) {
            $corDoTexto = 'DarkGray'
        }
        Write-Host "$recuo[" -NoNewline
        Write-Host $Marca -ForegroundColor $Cor -NoNewline
        Write-Host "] $($Etapa.Texto)" -ForegroundColor $corDoTexto -NoNewline:$atualizaNoLugar
    }

    if ($atualizaNoLugar) {
        [Console]::SetCursorPosition(0, $linhaDeVolta)
    }
}
