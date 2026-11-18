function Write-Log {
    <#
    .SYNOPSIS
    Grava uma linha no log do WinPlaybook, quando o nível dela está ligado.

    .DESCRIPTION
    A linha tem a data e a hora com o fuso, o nível, o número do processo e a mensagem. O
    primeiro registro de um dia cria o arquivo e apaga os logs com mais de 7 dias. Uma
    falha ao gravar não interrompe o comando. A mensagem não deve ter senhas nem valores de
    variáveis de ambiente.

    .PARAMETER Nivel
    O nível da linha: error, info ou debug.

    .PARAMETER Mensagem
    O texto da linha.

    .EXAMPLE
    Write-Log -Nivel 'info' -Mensagem 'ansible-playbook saiu com 0 em 1234 ms'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [ValidateSet('error', 'info', 'debug')] [string] $Nivel,
        [Parameter(Mandatory)] [string] $Mensagem
    )

    $numeroDoNivel = @{ error = 1; info = 2; debug = 3 }[$Nivel]
    $nivelEstaLigado = $numeroDoNivel -le (Get-NivelDoLog)
    if (-not $nivelEstaLigado) {
        return
    }

    try {
        $caminho = Get-CaminhoDoLog
        $ehOPrimeiroRegistroDoDia = -not (Test-Path -LiteralPath $caminho -PathType Leaf)
        if ($ehOPrimeiroRegistroDoDia) {
            $pastaDosLogs = Split-Path -Path $caminho -Parent
            $null = New-Item -ItemType Directory -Path $pastaDosLogs -Force -ErrorAction Stop
            $limite = (Get-Date).AddDays(-7)
            Get-ChildItem -LiteralPath $pastaDosLogs -Filter 'winplaybook-*.log' -File -ErrorAction Stop | Where-Object { $_.LastWriteTime -lt $limite } | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $linha = '{0} [{1}] [{2}] {3}' -f (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffzzz'), $Nivel.ToUpperInvariant(), $PID, $Mensagem
        [IO.File]::AppendAllText($caminho, $linha + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    }
    catch {
        return
    }
}
