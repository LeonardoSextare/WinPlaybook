function New-ChaveDoLocalhostWindows {
    <#
    .SYNOPSIS
    Cria na distribuição a chave SSH que o localhost_windows usa, quando ela ainda não existe, e devolve a chave pública.

    .DESCRIPTION
    A chave fica em ~/.config/winplaybook/localhost_windows, no disco da distribuição, com as
    permissões que o ssh exige, e some quando a distribuição é apagada.

    .PARAMETER Distribuicao
    A distribuição WSL do WinPlaybook.

    .EXAMPLE
    New-ChaveDoLocalhostWindows -Distribuicao 'WinPlaybook'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao
    )

    $script = 'pasta="$HOME/.config/winplaybook"; install -d -m 700 "$pasta"; [ -f "$pasta/localhost_windows" ] || ssh-keygen -q -t ed25519 -N "" -C winplaybook-localhost-windows -f "$pasta/localhost_windows"; cat "$pasta/localhost_windows.pub"'
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Distribuicao -Script $script -Usuario 'winplaybook'
    $criou = $resultado.CodigoDeSaida -eq 0
    if (-not $criou) {
        throw (Get-Mensagem -Nome 'ChaveDoLocalhostWindowsNaoCriada' -Valores $Distribuicao, $resultado.Saida)
    }

    return "$($resultado.Saida)".Trim()
}
