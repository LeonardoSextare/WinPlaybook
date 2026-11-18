function Remove-AutocompleteDoPerfil {
    <#
    .SYNOPSIS
    Tira de um perfil do PowerShell a linha que liga o autocomplete dos comandos do Ansible.

    .DESCRIPTION
    As outras linhas do perfil ficam como estão. Um perfil que fica vazio sem a linha é
    apagado, como o Add-AutocompleteNoPerfil o encontrou antes de criá-lo. Um perfil que não
    existe fica como está.

    .PARAMETER Perfil
    O caminho do perfil, como os de Get-PerfilDoPowerShell.

    .EXAMPLE
    Remove-AutocompleteDoPerfil -Perfil "$HOME\Documents\PowerShell\profile.ps1"
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Perfil
    )

    $perfilExiste = Test-Path -LiteralPath $Perfil -PathType Leaf
    if (-not $perfilExiste) {
        return
    }

    $linha = Get-LinhaDoAutocomplete
    $linhas = @([IO.File]::ReadAllLines($Perfil))
    $temALinha = $linhas -contains $linha
    if (-not $temALinha) {
        return
    }

    $outrasLinhas = @($linhas | Where-Object { $_ -ne $linha })
    $ficaVazio = -not ($outrasLinhas -join '').Trim()
    if ($ficaVazio) {
        Remove-Item -LiteralPath $Perfil -Force
        return
    }
    [IO.File]::WriteAllLines($Perfil, [string[]] $outrasLinhas, [Text.UTF8Encoding]::new($true))
}
