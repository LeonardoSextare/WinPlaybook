function Remove-PastaDoAnsibleVazia {
    <#
    .SYNOPSIS
    Apaga do perfil do usuário as pastas do Ansible que a instalação criou, quando estão vazias.

    .DESCRIPTION
    Apaga as pastas .ansible\collections, .ansible\roles e .ansible, nessa ordem, cada uma só
    quando está vazia. Uma pasta com arquivos, como uma collection instalada, fica.

    .PARAMETER PastaDoPerfil
    A pasta do perfil do usuário no Windows, como C:\Users\<usuário>.

    .EXAMPLE
    Remove-PastaDoAnsibleVazia -PastaDoPerfil 'C:\Users\eu'
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $PastaDoPerfil
    )

    $pastaDoAnsible = Join-Path -Path $PastaDoPerfil -ChildPath '.ansible'
    foreach ($pasta in (Join-Path -Path $pastaDoAnsible -ChildPath 'collections'), (Join-Path -Path $pastaDoAnsible -ChildPath 'roles'), $pastaDoAnsible) {
        Remove-PastaVazia -Pasta $pasta
    }
}
