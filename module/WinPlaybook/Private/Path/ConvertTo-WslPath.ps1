function ConvertTo-WslPath {
    <#
    .SYNOPSIS
    Converts an absolute Windows path to its path in the WSL distribution.

    .EXAMPLE
    ConvertTo-WslPath -Path 'C:\repo\playbooks\site.yml' -MountRoot '/mnt/'

    Returns /mnt/c/repo/playbooks/site.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $MountRoot
    )

    $isAbsoluteWindowsPath = $Path -match '^[A-Za-z]:[\\/]'
    if (-not $isAbsoluteWindowsPath) {
        throw "The path '$Path' is not an absolute Windows path."
    }

    $drive = $Path.Substring(0, 1).ToLowerInvariant()
    $pathInDrive = $Path.Substring(2).Replace('\', '/')
    $MountRoot.TrimEnd('/') + '/' + $drive + $pathInDrive
}
