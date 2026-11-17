function Get-PastaDoPerfilDoUsuario {
    <#
    .SYNOPSIS
    Devolve a pasta do perfil do usuário no Windows.

    .DESCRIPTION
    É a pasta onde o Windows guarda os arquivos do usuário, como o %USERPROFILE%. A
    distribuição usa a pasta .ansible e o arquivo .ansible.cfg dela como os do Ansible.

    .EXAMPLE
    Get-PastaDoPerfilDoUsuario

    Devolve C:\Users\<usuário>.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return [Environment]::GetFolderPath('UserProfile')
}
