function Get-VersaoMaisNovaDoWinPlaybook {
    <#
    .SYNOPSIS
    Consulta na PowerShell Gallery a versão mais nova do WinPlaybook.

    .DESCRIPTION
    Faz uma consulta só, com 5 segundos de limite, e falha quando a Gallery não responde.

    .EXAMPLE
    Get-VersaoMaisNovaDoWinPlaybook

    Devolve a versão, como 0.19.0.

    .LINK
    https://www.powershellgallery.com/packages/WinPlaybook
    #>
    [CmdletBinding()]
    [OutputType([version])]
    param()

    $ProgressPreference = 'SilentlyContinue'
    $resposta = Invoke-WebRequest -Uri "https://www.powershellgallery.com/api/v2/FindPackagesById()?id='WinPlaybook'&`$filter=IsLatestVersion" -UseBasicParsing -TimeoutSec 5
    $temVersao = $resposta.Content -match '<d:Version>(?<versao>[^<]+)</d:Version>'
    if (-not $temVersao) {
        throw 'A PowerShell Gallery não informou a versão do WinPlaybook.'
    }

    return [version] $Matches.versao
}
