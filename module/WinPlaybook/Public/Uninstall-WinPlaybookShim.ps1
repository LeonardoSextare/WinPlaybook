function Uninstall-WinPlaybookShim {
    <#
    .SYNOPSIS
    Apaga os shims de comando criados pelo Install-WinPlaybookShim e tira a pasta deles do Path do usuário.

    .DESCRIPTION
    Também apaga a configuração do WinPlaybook. A pasta escolhida com o -Path do
    Install-WinPlaybookShim fica, e só a pasta WinPlaybook criada dentro dela é apagada.

    .EXAMPLE
    Uninstall-WinPlaybookShim
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    $pastaDosShims = Get-PastaDosShims
    $confirmou = $PSCmdlet.ShouldProcess($pastaDosShims, 'Apagar os shims de comando do WinPlaybook')
    if (-not $confirmou) {
        return
    }

    Remove-PastaDosShims -Pasta $pastaDosShims
    Remove-Configuracao
}
