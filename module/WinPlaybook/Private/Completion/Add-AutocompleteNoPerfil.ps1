function Add-AutocompleteNoPerfil {
    <#
    .SYNOPSIS
    Acrescenta a um perfil do PowerShell a linha que liga o autocomplete dos comandos do Ansible.

    .DESCRIPTION
    A linha chama o Register-WinPlaybookArgumentCompleter quando o módulo está instalado.
    Um perfil que não existe é criado, com a pasta dele. Um perfil que já tem a linha fica
    como está.

    .PARAMETER Perfil
    O caminho do perfil, como os de Get-PerfilDoPowerShell.

    .EXAMPLE
    Add-AutocompleteNoPerfil -Perfil "$HOME\Documents\PowerShell\profile.ps1"
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Perfil
    )

    $linha = Get-LinhaDoAutocomplete
    $perfilExiste = Test-Path -LiteralPath $Perfil -PathType Leaf
    if (-not $perfilExiste) {
        $null = New-Item -ItemType Directory -Path (Split-Path -Path $Perfil -Parent) -Force
        [IO.File]::WriteAllText($Perfil, $linha + [Environment]::NewLine, [Text.UTF8Encoding]::new($true))
        return
    }

    $conteudo = [IO.File]::ReadAllText($Perfil)
    $jaTemALinha = @($conteudo -split '\r?\n') -contains $linha
    if ($jaTemALinha) {
        return
    }

    $separador = ''
    $terminaSemQuebraDeLinha = $conteudo.Length -gt 0 -and -not $conteudo.EndsWith("`n")
    if ($terminaSemQuebraDeLinha) {
        $separador = [Environment]::NewLine
    }
    [IO.File]::AppendAllText($Perfil, $separador + $linha + [Environment]::NewLine)
}
