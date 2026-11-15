function Remove-Configuracao {
    <#
    .SYNOPSIS
    Apaga a configuração do WinPlaybook e a pasta de configuração, quando ela fica vazia.

    .EXAMPLE
    Remove-Configuracao
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $pastaDeConfiguracao = Get-PastaDeConfiguracao
    Remove-Item -LiteralPath (Join-Path -Path $pastaDeConfiguracao -ChildPath 'settings.json') -ErrorAction SilentlyContinue
    Remove-PastaVazia -Pasta $pastaDeConfiguracao
}
