function Get-UsuarioDoLocalhostWindows {
    <#
    .SYNOPSIS
    Devolve o nome com que o OpenSSH Server do Windows reconhece o usuário atual.

    .DESCRIPTION
    Uma conta local vira só o nome, e uma conta de domínio vira domínio\nome, em
    minúsculas, como o sshd do Windows compara.

    .EXAMPLE
    Get-UsuarioDoLocalhostWindows

    Devolve eu, ou empresa\eu numa conta de domínio.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $nome = $env:USERNAME.ToLowerInvariant()
    $ehContaDeDominio = $env:USERDOMAIN -and ($env:USERDOMAIN -ne $env:COMPUTERNAME)
    if ($ehContaDeDominio) {
        return "$($env:USERDOMAIN.ToLowerInvariant())\$nome"
    }

    return $nome
}
