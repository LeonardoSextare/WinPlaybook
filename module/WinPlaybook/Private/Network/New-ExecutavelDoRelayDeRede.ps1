function New-ExecutavelDoRelayDeRede {
    <#
    .SYNOPSIS
    Compila o relay de rede, a partir do RelayDeRede.cs do módulo.

    .DESCRIPTION
    Com o argumento portas, o relay escreve na saída padrão, numa linha, as portas TCP em
    que o Windows escuta no localhost, e escreve de novo a cada mudança. Com conectar e uma
    porta, ele conecta nessa porta do localhost do Windows e repassa os bytes nos dois
    sentidos, até a entrada terminar. Quando não consegue conectar, escreve o erro no stderr
    e sai com 1.

    .PARAMETER Caminho
    O caminho do executável a criar. A pasta dele é criada quando não existe.

    .EXAMPLE
    New-ExecutavelDoRelayDeRede -Caminho 'C:\Temp\relay-de-rede.exe'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    New-ExecutavelCSharp -Codigo 'RelayDeRede.cs' -Caminho $Caminho
}
