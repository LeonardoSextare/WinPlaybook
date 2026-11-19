function Install-SshdDoWinPlaybook {
    <#
    .SYNOPSIS
    Cria e liga o serviço SSH do WinPlaybook, que só aceita a chave da distribuição e só escuta no 127.0.0.1.

    .DESCRIPTION
    Precisa de administrador e do OpenSSH Server instalado. O serviço WinPlaybookSshd roda o
    sshd do Windows com uma configuração própria, em %ProgramData%\WinPlaybook\ssh, separada
    da do sshd do usuário: a chave do servidor, a chave autorizada, só o usuário escolhido e
    nenhuma senha. A pasta só pode ser lida pelo SYSTEM e pelos administradores, como o sshd
    exige. Rodar de novo troca a configuração e reinicia o serviço.

    .PARAMETER ChavePublica
    A chave pública que pode entrar, de New-ChaveDoLocalhostWindows.

    .PARAMETER Usuario
    O usuário que pode entrar, de Get-UsuarioDoLocalhostWindows.

    .PARAMETER Porta
    A porta do 127.0.0.1 em que o serviço escuta.

    .PARAMETER PastaDoOpenSsh
    A pasta do OpenSSH de Install-OpenSshDoWinPlaybook, com o sshd.exe e o ssh-keygen.exe.

    .EXAMPLE
    Install-SshdDoWinPlaybook -ChavePublica $chave -Usuario 'eu' -Porta 47022 -PastaDoOpenSsh (Install-OpenSshDoWinPlaybook)
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $ChavePublica,
        [Parameter(Mandatory)] [string] $Usuario,
        [Parameter(Mandatory)] [int] $Porta,
        [Parameter(Mandatory)] [string] $PastaDoOpenSsh
    )

    $pasta = Get-PastaDoSshdDoWinPlaybook
    $sshd = Join-Path -Path $PastaDoOpenSsh -ChildPath 'sshd.exe'
    $sshKeygen = Join-Path -Path $PastaDoOpenSsh -ChildPath 'ssh-keygen.exe'
    $null = New-Item -ItemType Directory -Path $pasta -Force
    $null = & icacls.exe $pasta /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F'

    $chaveDoServidor = Join-Path -Path $pasta -ChildPath 'ssh_host_ed25519_key'
    $chaveDoServidorExiste = Test-Path -LiteralPath $chaveDoServidor -PathType Leaf
    if (-not $chaveDoServidorExiste) {
        $null = Start-Process -FilePath $sshKeygen -ArgumentList "-q -t ed25519 -N `"`" -f `"$chaveDoServidor`"" -Wait -NoNewWindow -PassThru
    }
    $null = & icacls.exe "$chaveDoServidor*" /reset

    $barras = $pasta.Replace('\', '/')
    [IO.File]::WriteAllText((Join-Path -Path $pasta -ChildPath 'authorized_keys'), $ChavePublica + "`n")
    $configuracao = @(
        "Port $Porta"
        'ListenAddress 127.0.0.1'
        "HostKey $barras/ssh_host_ed25519_key"
        "AuthorizedKeysFile $barras/authorized_keys"
        'PubkeyAuthentication yes'
        'PasswordAuthentication no'
        'KbdInteractiveAuthentication no'
        "AllowUsers `"$Usuario`""
        'Subsystem sftp sftp-server.exe'
    )
    $caminhoDaConfiguracao = Join-Path -Path $pasta -ChildPath 'sshd_config'
    [IO.File]::WriteAllText($caminhoDaConfiguracao, ($configuracao -join "`n") + "`n")
    $null = & icacls.exe $pasta /setowner '*S-1-5-32-544' /T

    $servico = Get-Service -Name 'WinPlaybookSshd' -ErrorAction SilentlyContinue
    if ($servico) {
        Stop-Service -Name 'WinPlaybookSshd' -Force -ErrorAction SilentlyContinue
    }
    else {
        $null = New-Service -Name 'WinPlaybookSshd' -DisplayName 'WinPlaybook SSH' -Description 'Deixa o Ansible do WinPlaybook configurar esta máquina pelo localhost_windows.' -BinaryPathName "`"$sshd`" -f `"$caminhoDaConfiguracao`"" -StartupType Automatic
    }
    $inicio = Get-Date
    try {
        Start-Service -Name 'WinPlaybookSshd' -ErrorAction Stop
    }
    catch {
        $eventosDoSshd = Get-WinEvent -FilterHashtable @{ LogName = 'OpenSSH/Operational'; StartTime = $inicio.AddSeconds(-5) } -ErrorAction SilentlyContinue
        $mensagensDoSshd = @($eventosDoSshd | ForEach-Object { $_.Message }) -join [Environment]::NewLine
        throw (Get-Mensagem -Nome 'ServicoSshNaoIniciou' -Valores $caminhoDaConfiguracao, $mensagensDoSshd)
    }
}
