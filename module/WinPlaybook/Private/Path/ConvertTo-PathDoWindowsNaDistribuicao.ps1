function ConvertTo-PathDoWindowsNaDistribuicao {
    <#
    .SYNOPSIS
    Converte as pastas do Path do Windows para as pastas delas na montagem com execução da distribuição.

    .DESCRIPTION
    A distribuição monta cada unidade fixa do Windows uma segunda vez, em
    /opt/winplaybook/exec/<unidade>, com permissão de execução, e é por ela que os programas
    do Windows rodam. Cada pasta com a letra da unidade vira a pasta dela nessa montagem, na
    mesma ordem do Path e sem repetir. Ficam de fora a pasta dos shims do WinPlaybook, que
    levaria o comando de volta ao Windows, e as pastas que não têm a letra da unidade.

    .PARAMETER Path
    O Path do Windows, com as pastas separadas por ponto e vírgula.

    .PARAMETER PastaDosShims
    A pasta dos shims do WinPlaybook.

    .EXAMPLE
    ConvertTo-PathDoWindowsNaDistribuicao -Path 'C:\Windows\system32;C:\Users\eu\.local\bin' -PastaDosShims 'C:\Users\eu\AppData\Local\WinPlaybook\bin'

    Devolve /opt/winplaybook/exec/c/Windows/system32 e /opt/winplaybook/exec/c/Users/eu/.local/bin.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Path,
        [AllowEmptyString()] [string] $PastaDosShims
    )

    $pastaDosShimsSemBarra = "$PastaDosShims".TrimEnd('\')
    $pastas = [ordered]@{}
    foreach ($pasta in $Path.Split(';')) {
        $pastaSemBarra = $pasta.Trim().TrimEnd('\')
        $temLetraDeUnidade = $pastaSemBarra -match '^[A-Za-z]:'
        $ehAPastaDosShims = $pastaSemBarra -eq $pastaDosShimsSemBarra
        if (-not $temLetraDeUnidade -or $ehAPastaDosShims) {
            continue
        }

        $pastaNaDistribuicao = '/opt/winplaybook/exec/' + $pastaSemBarra.Substring(0, 1).ToLowerInvariant() + $pastaSemBarra.Substring(2).Replace('\', '/')
        $pastas[$pastaNaDistribuicao.ToLowerInvariant()] = $pastaNaDistribuicao
    }

    return @($pastas.Values)
}
