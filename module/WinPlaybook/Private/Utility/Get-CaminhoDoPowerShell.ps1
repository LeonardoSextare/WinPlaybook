function Get-CaminhoDoPowerShell {
    <#
    .SYNOPSIS
    Devolve o caminho do PowerShell que os shims de comando abrem.

    .PARAMETER Edicao
    Desktop para o Windows PowerShell 5.1, que abre mais rápido, ou Core para o PowerShell 7.

    .EXAMPLE
    Get-CaminhoDoPowerShell -Edicao 'Desktop'

    Devolve C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [ValidateSet('Desktop', 'Core')] [string] $Edicao
    )

    $ehDesktop = $Edicao -eq 'Desktop'
    if ($ehDesktop) {
        return Join-Path -Path $env:SystemRoot -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
    }

    $pwsh = Get-Command -Name 'pwsh' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $pwshEstaInstalado = [bool] $pwsh
    if (-not $pwshEstaInstalado) {
        throw (Get-Mensagem -Nome 'PowerShell7NaoInstalado')
    }

    return $pwsh.Source
}
