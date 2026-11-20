function Get-CaminhoDosCertificadosDoWindows {
    <#
    .SYNOPSIS
    Grava os certificados raiz do Windows num arquivo PEM, quando ele ainda não existe, e devolve o caminho dele.

    .DESCRIPTION
    O arquivo fica em %TEMP%\WinPlaybook, com o hash das impressões digitais dos certificados
    no nome, então um certificado novo no Windows gera um arquivo novo, e os mesmos
    certificados não são lidos nem gravados de novo.

    .EXAMPLE
    Get-CaminhoDosCertificadosDoWindows

    Devolve C:\Users\<usuário>\AppData\Local\Temp\WinPlaybook\certificados-<hash>.pem.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $certificados = @(Get-CertificadoRaizDoWindows)
    $impressoesDigitais = [Text.Encoding]::ASCII.GetBytes((-join ($certificados | ForEach-Object { $_.Thumbprint })))
    $algoritmo = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = -join ($algoritmo.ComputeHash($impressoesDigitais)[0..7] | ForEach-Object { $_.ToString('x2') })
    }
    finally {
        $algoritmo.Dispose()
    }

    $pasta = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WinPlaybook'
    $caminho = Join-Path -Path $pasta -ChildPath "certificados-$hash.pem"
    $jaFoiGravado = Test-Path -LiteralPath $caminho -PathType Leaf
    if (-not $jaFoiGravado) {
        $blocos = foreach ($certificado in $certificados) {
            $base64 = [Convert]::ToBase64String($certificado.RawData)
            $linhas = [regex]::Matches($base64, '.{1,64}') | ForEach-Object { $_.Value }
            Write-Output ("-----BEGIN CERTIFICATE-----`n" + ($linhas -join "`n") + "`n-----END CERTIFICATE-----`n")
        }
        $null = New-Item -ItemType Directory -Path $pasta -Force
        $caminhoTemporario = "$caminho.$PID"
        [IO.File]::WriteAllBytes($caminhoTemporario, [Text.Encoding]::ASCII.GetBytes((-join $blocos)))
        Move-Item -LiteralPath $caminhoTemporario -Destination $caminho -Force
    }
    return $caminho
}
