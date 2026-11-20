function Copy-Executavel {
    <#
    .SYNOPSIS
    Copia um executável para a pasta dos shims, mesmo quando o anterior está em execução.

    .DESCRIPTION
    Um executável anterior que está em execução é renomeado com a extensão
    .winplaybook-antigo e apagado quando é liberado, numa cópia seguinte. Uma cópia que
    falha interrompe o comando.

    .PARAMETER Origem
    O executável que é copiado.

    .PARAMETER Destino
    O caminho do executável na pasta dos shims.

    .EXAMPLE
    Copy-Executavel -Origem $caminhoDoExecutavel -Destino (Join-Path -Path $pastaDosShims -ChildPath 'ansible.exe')
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Origem,
        [Parameter(Mandatory)] [string] $Destino
    )

    $pasta = Split-Path -Path $Destino -Parent
    foreach ($antigo in @(Get-ChildItem -LiteralPath $pasta -File | Where-Object { $_.Extension -eq '.winplaybook-antigo' })) {
        Remove-Item -LiteralPath $antigo.FullName -Force -ErrorAction SilentlyContinue
    }

    $destinoExiste = Test-Path -LiteralPath $Destino -PathType Leaf
    if ($destinoExiste) {
        $caminhoDoAntigo = "$Destino.$([guid]::NewGuid().ToString('N')).winplaybook-antigo"
        Move-Item -LiteralPath $Destino -Destination $caminhoDoAntigo -Force -ErrorAction Stop
        Remove-Item -LiteralPath $caminhoDoAntigo -Force -ErrorAction SilentlyContinue
    }

    Copy-Item -LiteralPath $Origem -Destination $Destino -ErrorAction Stop
}
