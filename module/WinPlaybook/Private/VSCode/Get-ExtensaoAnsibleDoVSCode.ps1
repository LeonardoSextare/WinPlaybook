function Get-ExtensaoAnsibleDoVSCode {
    <#
    .SYNOPSIS
    Lista as pastas da extensão Ansible do VS Code (redhat.ansible) instaladas, com a versão de cada uma.

    .DESCRIPTION
    Procura as pastas redhat.ansible-<versão> na pasta das extensões do VS Code e devolve um
    objeto com Versao e Caminho para cada uma.

    .PARAMETER PastaDasExtensoes
    A pasta das extensões do VS Code, como %USERPROFILE%\.vscode\extensions.

    .EXAMPLE
    Get-ExtensaoAnsibleDoVSCode -PastaDasExtensoes "$env:USERPROFILE\.vscode\extensions"
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string] $PastaDasExtensoes
    )

    $pastaExiste = Test-Path -LiteralPath $PastaDasExtensoes -PathType Container
    if (-not $pastaExiste) {
        return
    }

    foreach ($pasta in Get-ChildItem -LiteralPath $PastaDasExtensoes -Directory) {
        $ehDaExtensaoAnsible = $pasta.Name -match '^redhat\.ansible-(?<versao>\d+\.\d+\.\d+)$'
        if ($ehDaExtensaoAnsible) {
            Write-Output ([pscustomobject]@{ Versao = $Matches.versao; Caminho = $pasta.FullName })
        }
    }
}
