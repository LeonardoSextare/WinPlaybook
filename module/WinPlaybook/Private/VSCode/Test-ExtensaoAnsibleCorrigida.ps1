function Test-ExtensaoAnsibleCorrigida {
    <#
    .SYNOPSIS
    Diz se uma pasta da extensão Ansible do VS Code tem as correções do WinPlaybook.

    .DESCRIPTION
    A pasta está corrigida quando guarda algum arquivo original com a extensão
    .winplaybook-original, que o Install-PatchDaExtensaoAnsible cria.

    .PARAMETER Caminho
    A pasta da extensão, como C:\Users\<usuário>\.vscode\extensions\redhat.ansible-26.11.0.

    .EXAMPLE
    Test-ExtensaoAnsibleCorrigida -Caminho $extensao.Caminho
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string] $Caminho
    )

    $original = Get-ChildItem -LiteralPath $Caminho -Recurse -File -Filter '*.winplaybook-original' -ErrorAction SilentlyContinue | Select-Object -First 1
    return $null -ne $original
}
