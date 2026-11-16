function Test-CaminhoRelativoDoWindows {
    <#
    .SYNOPSIS
    Diz se um texto com barras invertidas é um caminho relativo do Windows, a partir da pasta atual.

    .DESCRIPTION
    É um caminho quando começa com .\ ou ..\, como os caminhos que o autocompletar do
    PowerShell cria, ou quando a pasta dele existe, mesmo que o arquivo ainda não exista.
    Textos com barras invertidas que não são caminhos, como o padrão de hosts ~web\d+, ficam
    de fora.

    .PARAMETER Caminho
    O texto, como o usuário passou.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado.

    .EXAMPLE
    Test-CaminhoRelativoDoWindows -Caminho 'saida\inventario.json' -PastaAtual 'C:\repo'

    Devolve True quando a pasta C:\repo\saida existe, mesmo sem o inventario.json.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Caminho,
        [Parameter(Mandatory)] [string] $PastaAtual
    )

    $temBarraInvertida = $Caminho.Contains('\')
    if (-not $temBarraInvertida) {
        return $false
    }

    $comecaNaPastaAtualOuAcima = $Caminho.StartsWith('.\', [StringComparison]::Ordinal) -or $Caminho.StartsWith('..\', [StringComparison]::Ordinal)
    if ($comecaNaPastaAtualOuAcima) {
        return $true
    }

    $comecaNaRaiz = $Caminho.StartsWith('\', [StringComparison]::Ordinal)
    $temCaractereInvalido = $Caminho.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0
    if ($comecaNaRaiz -or $temCaractereInvalido) {
        return $false
    }

    $pastaDoCaminho = Split-Path -Path (Join-Path -Path $PastaAtual -ChildPath $Caminho) -Parent
    return Test-Path -LiteralPath $pastaDoCaminho -PathType Container
}
