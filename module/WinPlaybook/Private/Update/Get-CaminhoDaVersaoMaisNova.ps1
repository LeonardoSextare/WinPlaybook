function Get-CaminhoDaVersaoMaisNova {
    <#
    .SYNOPSIS
    Devolve o arquivo que guarda a última versão do WinPlaybook encontrada na PowerShell Gallery.

    .EXAMPLE
    Get-CaminhoDaVersaoMaisNova

    Devolve C:\Users\<usuário>\AppData\Local\WinPlaybook\versao-mais-nova.json.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path -Path (Get-PastaDeConfiguracao) -ChildPath 'versao-mais-nova.json'
}
