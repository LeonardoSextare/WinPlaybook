function Install-RelayDeRede {
    <#
    .SYNOPSIS
    Copia o relay de rede para a pasta dos shims e o deixa executável na distribuição WSL.

    .DESCRIPTION
    A distribuição monta as unidades do Windows com os arquivos sem permissão de execução, e
    o relay recebe a permissão pelo chmod, que a distribuição guarda no próprio arquivo.
    Assim o supervisor dos comandos consegue executar o relay, que roda no Windows.

    .PARAMETER CaminhoDoExecutavel
    O relay que New-ExecutavelDoRelayDeRede compilou.

    .PARAMETER PastaDosShims
    A pasta dos shims, onde o relay fica, na subpasta exe.

    .PARAMETER Distribuicao
    A distribuição WSL do WinPlaybook.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .EXAMPLE
    Install-RelayDeRede -CaminhoDoExecutavel 'C:\Temp\relay-de-rede.exe' -PastaDosShims 'C:\Tools\WinPlaybook\bin' -Distribuicao 'WinPlaybook' -RaizDeMontagem '/mnt/'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $CaminhoDoExecutavel,
        [Parameter(Mandatory)] [string] $PastaDosShims,
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $RaizDeMontagem
    )

    $caminhoDoRelay = Get-CaminhoDoRelayDeRede -PastaDosShims $PastaDosShims
    $null = New-Item -ItemType Directory -Path (Split-Path -Path $caminhoDoRelay -Parent) -Force
    Copy-Item -LiteralPath $CaminhoDoExecutavel -Destination $caminhoDoRelay -Force

    $caminhoNaDistribuicao = ConvertTo-CaminhoDoWsl -Caminho $caminhoDoRelay -RaizDeMontagem $RaizDeMontagem
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Distribuicao -Script 'chmod +x "$1"' -Argumentos $caminhoNaDistribuicao -Usuario 'root'
    $ficouExecutavel = $resultado.CodigoDeSaida -eq 0
    if (-not $ficouExecutavel) {
        throw (Get-Mensagem -Nome 'RelayDeRedeNaoInstalado' -Valores $caminhoDoRelay, $resultado.Saida)
    }
}
