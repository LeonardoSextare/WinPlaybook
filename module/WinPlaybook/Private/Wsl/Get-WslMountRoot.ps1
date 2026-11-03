function Get-WslMountRoot {
    <#
    .SYNOPSIS
    Returns the folder where a WSL distribution mounts the Windows drives.

    .DESCRIPTION
    Most distributions mount the C: drive at /mnt/c, but the automount root of
    /etc/wsl.conf can change the folder.

    .EXAMPLE
    Get-WslMountRoot -Distribution 'Ubuntu'

    Returns /mnt/.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Distribution
    )

    $ErrorActionPreference = 'Continue'
    $drivePath = wsl --distribution $Distribution --exec wslpath -a 'C:\' 2>$null

    $isTranslated = ($LASTEXITCODE -eq 0) -and ("$drivePath" -match '^/(.*/)?c/$')
    if (-not $isTranslated) {
        throw "Could not find where the WSL distribution $Distribution mounts the Windows drives (wsl exit code $LASTEXITCODE)."
    }

    "$drivePath".Substring(0, "$drivePath".Length - 'c/'.Length)
}
