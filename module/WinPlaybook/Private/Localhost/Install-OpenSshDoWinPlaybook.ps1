function Install-OpenSshDoWinPlaybook {
    <#
    .SYNOPSIS
    Baixa o OpenSSH da release oficial da Microsoft no GitHub e o deixa numa pasta só do WinPlaybook, e devolve essa pasta.

    .DESCRIPTION
    Precisa de administrador. O zip OpenSSH-Win64 da versão fixada em Get-PacoteDoOpenSsh é
    baixado do repositório PowerShell/Win32-OpenSSH, conferido pelo SHA256 e extraído em
    %ProgramData%\WinPlaybook\openssh, que fica só para o SYSTEM e os administradores, com
    leitura para os usuários, porque o serviço do WinPlaybook roda esse sshd.exe como SYSTEM.
    Nada é instalado no Windows: o recurso OpenSSH Server, o ssh-agent e o cliente ssh do
    usuário ficam como estão. Com a mesma versão já extraída, nada é baixado.

    .EXAMPLE
    $pastaDoOpenSsh = Install-OpenSshDoWinPlaybook
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $pacote = Get-PacoteDoOpenSsh
    $pasta = Get-PastaDoOpenSshDoWinPlaybook
    $arquivoDaVersao = Join-Path -Path $pasta -ChildPath 'winplaybook-versao.txt'
    $versaoInstalada = ''
    $temVersao = Test-Path -LiteralPath $arquivoDaVersao -PathType Leaf
    if ($temVersao) {
        $versaoInstalada = [IO.File]::ReadAllText($arquivoDaVersao).Trim()
    }
    $jaEstaInstalado = $versaoInstalada -eq $pacote.Versao -and (Test-Path -LiteralPath (Join-Path -Path $pasta -ChildPath 'sshd.exe') -PathType Leaf)
    if ($jaEstaInstalado) {
        return $pasta
    }

    $pastaTemporaria = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "WinPlaybook-openssh-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $pastaTemporaria -Force
    try {
        $zip = Join-Path -Path $pastaTemporaria -ChildPath 'OpenSSH-Win64.zip'
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $pacote.Url -OutFile $zip -UseBasicParsing -ErrorAction Stop
        }
        catch {
            throw (Get-Mensagem -Nome 'OpenSshNaoBaixado' -Valores $pacote.Url, $_.Exception.Message)
        }

        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        $hashConfere = $hash -eq $pacote.Sha256
        if (-not $hashConfere) {
            throw (Get-Mensagem -Nome 'OpenSshCorrompido' -Valores $pacote.Url)
        }

        Expand-Archive -LiteralPath $zip -DestinationPath $pastaTemporaria -Force
        Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction SilentlyContinue
        $null = New-Item -ItemType Directory -Path (Split-Path -Path $pasta -Parent) -Force
        Move-Item -LiteralPath (Join-Path -Path $pastaTemporaria -ChildPath 'OpenSSH-Win64') -Destination $pasta
        $null = & icacls.exe $pasta /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX'
        [IO.File]::WriteAllText($arquivoDaVersao, $pacote.Versao)
    }
    finally {
        Remove-Item -LiteralPath $pastaTemporaria -Recurse -Force -ErrorAction SilentlyContinue
    }

    return $pasta
}
