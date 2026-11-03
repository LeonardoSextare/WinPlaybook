function Get-WslDistribution {
    <#
    .SYNOPSIS
    Lists the names of the WSL distributions installed on this computer.

    .EXAMPLE
    Get-WslDistribution

    Returns Ubuntu and the other distributions that wsl --list shows.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $isWslInstalled = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $isWslInstalled) {
        throw 'WSL was not found. WinPlaybook runs Ansible in a WSL distribution: install WSL with wsl --install and try again.'
    }

    # wsl.exe writes its own messages in UTF-16 unless WSL_UTF8 is set.
    $originalUtf8 = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $ErrorActionPreference = 'Continue'
        $listing = wsl --list --quiet 2>$null
    }
    finally {
        $env:WSL_UTF8 = $originalUtf8
    }

    $isListed = $LASTEXITCODE -eq 0
    if (-not $isListed) {
        throw 'WSL has no distributions. Install one with wsl --install, install Ansible in it, and try again.'
    }

    @($listing | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
}
