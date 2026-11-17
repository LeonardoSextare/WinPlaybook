function New-ExecutavelDoRelay {
    <#
    .SYNOPSIS
    Compila o relay do agente SSH, a partir do RelayDoAgenteSsh.cs do módulo.

    .DESCRIPTION
    O relay recebe o nome de um named pipe do Windows, como openssh-ssh-agent, conecta nele
    e repassa os bytes nos dois sentidos: o que chega pela entrada padrão vai para o pipe, e
    o que o pipe responde vai para a saída padrão. Ele sai quando a entrada termina. Quando
    não consegue conectar no pipe, escreve o erro no stderr e sai com 1.

    .PARAMETER Caminho
    O caminho do executável a criar. A pasta dele é criada quando não existe.

    .EXAMPLE
    New-ExecutavelDoRelay -Caminho 'C:\Temp\relay-do-agente-ssh.exe'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    New-ExecutavelCSharp -Codigo 'RelayDoAgenteSsh.cs' -Caminho $Caminho
}
