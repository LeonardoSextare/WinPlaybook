function Repair-InteropDoWsl {
    <#
    .SYNOPSIS
    Registra de novo o interop do WSL quando outra distribuição o apagou, para a distribuição voltar a executar programas do Windows.

    .DESCRIPTION
    Confere o registro WSLInterop do binfmt_misc da VM do WSL pelo \\wsl.localhost e, só quando
    ele falta, como depois que uma distribuição com systemd o apaga, o registra de novo como
    root. Uma falha no registro vai para o log e não interrompe o comando.

    .PARAMETER Distribuicao
    A distribuição WSL, como o wsl --list mostra.

    .EXAMPLE
    Repair-InteropDoWsl -Distribuicao 'WinPlaybook'

    .LINK
    https://github.com/microsoft/WSL/issues/8843
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao
    )

    $registroDoInterop = "\\wsl.localhost\$Distribuicao\proc\sys\fs\binfmt_misc\WSLInterop"
    $interopEstaRegistrado = Test-Path -LiteralPath $registroDoInterop
    if ($interopEstaRegistrado) {
        return
    }

    $script = 'test -e /proc/sys/fs/binfmt_misc/WSLInterop || printf ''%s'' '':WSLInterop:M::MZ::/init:PF'' > /proc/sys/fs/binfmt_misc/register'
    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Distribuicao -Script $script -Usuario 'root'
    $registrou = $resultado.CodigoDeSaida -eq 0
    if (-not $registrou) {
        Write-Log -Nivel 'error' -Mensagem "O registro WSLInterop da distribuição $Distribuicao não foi refeito: $($resultado.Saida)"
        return
    }
    Write-Log -Nivel 'info' -Mensagem "O registro WSLInterop da distribuição $Distribuicao foi refeito, porque outra distribuição o apagou"
}
