function Install-ServidorOpenSsh {
    <#
    .SYNOPSIS
    Instala o recurso opcional OpenSSH Server do Windows, quando ele ainda não está instalado, e diz se instalou.

    .DESCRIPTION
    Precisa de administrador. O Windows baixa o recurso da Microsoft, ou do servidor de
    atualizações da empresa, e isso pode levar alguns minutos. O serviço sshd que o recurso
    cria fica parado: o WinPlaybook usa um serviço próprio. Devolve $true quando instalou o
    recurso agora, e $false quando ele já estava instalado.

    .EXAMPLE
    Install-ServidorOpenSsh

    .LINK
    https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $jaEstaInstalado = Test-Path -LiteralPath (Join-Path -Path $env:WINDIR -ChildPath 'System32\OpenSSH\sshd.exe') -PathType Leaf
    if ($jaEstaInstalado) {
        return $false
    }

    $recurso = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop | Select-Object -First 1
    $null = Add-WindowsCapability -Online -Name $recurso.Name -ErrorAction Stop
    return $true
}
