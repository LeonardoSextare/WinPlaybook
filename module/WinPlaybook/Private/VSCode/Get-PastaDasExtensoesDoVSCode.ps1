function Get-PastaDasExtensoesDoVSCode {
    <#
    .SYNOPSIS
    Devolve a pasta das extensões do VS Code do usuário.

    .EXAMPLE
    Get-PastaDasExtensoesDoVSCode

    Devolve C:\Users\<usuário>\.vscode\extensions.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.vscode\extensions'
}
