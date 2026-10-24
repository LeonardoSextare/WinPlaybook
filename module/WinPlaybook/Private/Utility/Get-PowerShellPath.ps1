function Get-PowerShellPath {
    <#
    .SYNOPSIS
    Returns the path of the PowerShell that the command shims start.

    .DESCRIPTION
    Without an edition, it is the PowerShell that is running, where the module is
    installed. Desktop is Windows PowerShell 5.1, which starts faster; Core is PowerShell 7.

    .EXAMPLE
    Get-PowerShellPath -Edition 'Desktop'

    Returns C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [ValidateSet('Desktop', 'Core')] [string] $Edition
    )

    $isEditionChosen = [bool] $Edition
    if (-not $isEditionChosen) {
        return (Get-Process -Id $PID).Path
    }

    $isDesktop = $Edition -eq 'Desktop'
    if ($isDesktop) {
        return Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    }

    $pwsh = Get-Command -Name 'pwsh' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $isPwshInstalled = [bool] $pwsh
    if (-not $isPwshInstalled) {
        throw 'PowerShell 7 (pwsh) is not installed. Install it with: winget install Microsoft.PowerShell'
    }

    $pwsh.Source
}
