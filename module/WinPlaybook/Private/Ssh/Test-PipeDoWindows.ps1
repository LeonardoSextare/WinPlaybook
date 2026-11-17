function Test-PipeDoWindows {
    <#
    .SYNOPSIS
    Diz se existe um named pipe do Windows com o nome escolhido, sem conectar nele.

    .PARAMETER Nome
    O nome do pipe, sem o \\.\pipe\, como openssh-ssh-agent.

    .EXAMPLE
    Test-PipeDoWindows -Nome 'openssh-ssh-agent'

    Devolve $true quando o agente SSH do Windows está rodando.

    .LINK
    https://learn.microsoft.com/windows/win32/ipc/pipe-names
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string] $Nome
    )

    $caminhoDoPipe = "\\.\pipe\$Nome"
    try {
        $existe = [IO.Directory]::GetFiles('\\.\pipe\') -contains $caminhoDoPipe
    }
    catch {
        $existe = Test-Path -LiteralPath $caminhoDoPipe
    }

    return $existe
}
