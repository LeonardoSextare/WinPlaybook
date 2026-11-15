function ConvertTo-ArgumentoNativoLegado {
    <#
    .SYNOPSIS
    Escapa argumentos para a forma antiga com que o PowerShell passa argumentos a programas.

    .DESCRIPTION
    Escapa as aspas e as barras invertidas de cada argumento com as regras que os programas
    do Windows usam para separar a linha de comando. Assim, um programa como o wsl recebe
    {"a": 1} como foi passado, e não {a: 1}. Um argumento vazio vira "".

    .PARAMETER Argumento
    Os argumentos, na ordem em que vão para o programa.

    .EXAMPLE
    ConvertTo-ArgumentoNativoLegado -Argumento '-e', '{"a": 1}'

    Devolve -e e {\"a\": 1}.

    .LINK
    https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [AllowEmptyString()] [string[]] $Argumento
    )

    foreach ($valor in $Argumento) {
        $estaVazio = $valor -eq ''
        if ($estaVazio) {
            Write-Output '""'
            continue
        }

        $valorEscapado = $valor -replace '(\\*)"', '$1$1\"'

        $temEspaco = $valorEscapado -match '\s'
        if ($temEspaco) {
            $valorEscapado = $valorEscapado -replace '(\\+)$', '$1$1'
        }

        Write-Output $valorEscapado
    }
}
