function Update-VersaoMaisNovaGuardada {
    <#
    .SYNOPSIS
    Consulta a versão mais nova do WinPlaybook e a guarda, com a data da consulta.

    .DESCRIPTION
    Grava o arquivo de Get-CaminhoDaVersaoMaisNova com a versão (versao) e a hora da consulta
    (verificadoEm). Sem resposta da Gallery, como sem internet, grava só a hora, para a
    próxima consulta esperar um dia.

    .EXAMPLE
    Update-VersaoMaisNovaGuardada
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $versao = ''
    try {
        $versao = "$(Get-VersaoMaisNovaDoWinPlaybook)"
    }
    catch {
        $versao = ''
    }

    $caminho = Get-CaminhoDaVersaoMaisNova
    $null = New-Item -ItemType Directory -Path (Split-Path -Path $caminho -Parent) -Force
    $registro = ConvertTo-Json -InputObject @{ versao = $versao; verificadoEm = (Get-Date).ToString('o') } -Compress
    [IO.File]::WriteAllText($caminho, $registro)
}
