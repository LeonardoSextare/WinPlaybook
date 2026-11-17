function Get-CaminhoDoSupervisor {
    <#
    .SYNOPSIS
    Grava o script do supervisor numa pasta temporária do Windows, quando ele ainda não está lá, e devolve o caminho dele.

    .DESCRIPTION
    O arquivo fica em %TEMP%\WinPlaybook, com o hash do conteúdo no nome, então cada versão
    do script tem o próprio arquivo e uma versão já gravada não é gravada de novo. A
    distribuição lê o arquivo pela unidade do Windows, e a linha de comando do wsl.exe leva
    só o caminho, em vez do código inteiro.

    .EXAMPLE
    Get-CaminhoDoSupervisor

    Devolve C:\Users\<usuário>\AppData\Local\Temp\WinPlaybook\supervisor-<hash>.py.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $conteudo = [Text.Encoding]::UTF8.GetBytes((Get-ScriptDoSupervisor))
    $algoritmo = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = -join ($algoritmo.ComputeHash($conteudo)[0..7] | ForEach-Object { $_.ToString('x2') })
    }
    finally {
        $algoritmo.Dispose()
    }

    $pasta = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WinPlaybook'
    $caminho = Join-Path -Path $pasta -ChildPath "supervisor-$hash.py"
    $jaFoiGravado = Test-Path -LiteralPath $caminho -PathType Leaf
    if (-not $jaFoiGravado) {
        $null = New-Item -ItemType Directory -Path $pasta -Force
        $caminhoTemporario = "$caminho.$PID"
        [IO.File]::WriteAllBytes($caminhoTemporario, $conteudo)
        Move-Item -LiteralPath $caminhoTemporario -Destination $caminho -Force
    }

    return $caminho
}
