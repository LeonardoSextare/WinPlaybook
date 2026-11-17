function New-ExecutavelDeShim {
    <#
    .SYNOPSIS
    Compila o executável que os shims .exe copiam, a partir do Shim.cs do módulo.

    .DESCRIPTION
    O executável lê o <nome>.shim que fica ao lado dele, com o programa (path) e os
    argumentos dele (args), e executa esse programa com a mesma entrada, as mesmas saídas e
    o mesmo console. Os argumentos que o executável recebe vão depois dos args, cada um como
    um x seguido do texto em UTF-8 codificado em Base64. Assim nenhum argumento chega ao
    PowerShell num formato que o -File interprete. O executável sai com o código de saída do
    programa.

    .PARAMETER Caminho
    O caminho do executável a criar. A pasta dele é criada quando não existe.

    .EXAMPLE
    New-ExecutavelDeShim -Caminho 'C:\Temp\shim.exe'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    New-ExecutavelCSharp -Codigo 'Shim.cs' -Caminho $Caminho
}
