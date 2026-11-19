function Write-LinhaDaEtapa {
    <#
    .SYNOPSIS
    Escreve no console a linha final de uma etapa, com a marca colorida antes do texto.

    .DESCRIPTION
    A marca, como [+] ou [x], aparece na cor pedida, e o texto na cor normal do console.

    .PARAMETER Marca
    A marca da linha, como [+] para uma etapa concluída ou [x] para uma que falhou.

    .PARAMETER Cor
    A cor da marca.

    .PARAMETER Texto
    O texto da linha.

    .EXAMPLE
    Write-LinhaDaEtapa -Marca '[+]' -Cor 'Green' -Texto 'Ansible instalado'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Marca,
        [Parameter(Mandatory)] [ConsoleColor] $Cor,
        [Parameter(Mandatory)] [string] $Texto
    )

    Write-Host '  ' -NoNewline
    Write-Host $Marca -ForegroundColor $Cor -NoNewline
    Write-Host " $Texto"
}
