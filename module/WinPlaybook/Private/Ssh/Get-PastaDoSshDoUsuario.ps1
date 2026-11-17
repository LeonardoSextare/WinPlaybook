function Get-PastaDoSshDoUsuario {
    <#
    .SYNOPSIS
    Devolve a pasta .ssh do perfil do usuário no Windows.

    .DESCRIPTION
    É a pasta que o ssh do Windows usa e que a distribuição monta como ~/.ssh. Ela pode não
    existir.

    .EXAMPLE
    Get-PastaDoSshDoUsuario

    Devolve C:\Users\<usuário>\.ssh.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.ssh'
}
