function Get-LinhaDoAutocomplete {
    <#
    .SYNOPSIS
    Devolve a linha que o perfil do PowerShell recebe para ligar o autocomplete dos comandos do Ansible.

    .EXAMPLE
    Get-LinhaDoAutocomplete
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return 'if (Get-Command -Name Register-WinPlaybookArgumentCompleter -ErrorAction SilentlyContinue) { Register-WinPlaybookArgumentCompleter }'
}
