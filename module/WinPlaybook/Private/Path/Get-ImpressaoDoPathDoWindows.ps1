function Get-ImpressaoDoPathDoWindows {
    <#
    .SYNOPSIS
    Devolve um hash das pastas do Path do Windows e da data de modificação de cada uma.

    .DESCRIPTION
    O hash muda quando o Path ganha, perde ou troca uma pasta, ou quando um programa entra ou
    sai de uma pasta dele. Uma pasta que não existe entra no hash sem data.

    .PARAMETER Path
    O Path do Windows, com as pastas separadas por ponto e vírgula.

    .EXAMPLE
    Get-ImpressaoDoPathDoWindows -Path $env:Path

    Devolve um hash em hexadecimal, com 64 caracteres.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Path
    )

    $estado = foreach ($pasta in $Path.Split(';')) {
        $informacoes = [IO.DirectoryInfo]::new($pasta)
        $data = '-'
        $pastaExiste = $pasta -and $informacoes.Exists
        if ($pastaExiste) {
            $data = $informacoes.LastWriteTimeUtc.Ticks
        }
        Write-Output "$pasta`t$data"
    }
    $algoritmo = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algoritmo.ComputeHash([Text.Encoding]::UTF8.GetBytes((@($estado) -join "`n")))
    }
    finally {
        $algoritmo.Dispose()
    }
    return -join ($hash | ForEach-Object { $_.ToString('x2') })
}
