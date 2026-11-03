function ConvertTo-WslArgument {
    <#
    .SYNOPSIS
    Converts a Windows path in a command argument to its path in the WSL distribution.

    .DESCRIPTION
    An absolute path becomes a path under the folder where the distribution mounts the
    drives. A relative path with backslashes gets forward slashes, but only when it
    exists: other arguments may contain backslashes that are not paths. The path can
    come after an option (--inventory=) and after @, as in -e @vars\prod.yml.

    .EXAMPLE
    ConvertTo-WslArgument -Argument '.\site.yml' -MountRoot '/mnt/' -CurrentFolder 'C:\repo'

    Returns ./site.yml.

    .EXAMPLE
    ConvertTo-WslArgument -Argument '--inventory=C:\repo\hosts.yml' -MountRoot '/mnt/' -CurrentFolder 'C:\repo'

    Returns --inventory=/mnt/c/repo/hosts.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Argument,
        [Parameter(Mandatory)] [string] $MountRoot,
        [Parameter(Mandatory)] [string] $CurrentFolder
    )

    $null = $Argument -match '^(?<prefix>(--[\w-]+=)?@?)(?<value>.*)$'
    $prefix = $Matches.prefix
    $value = $Matches.value

    $isAbsoluteWindowsPath = $value -match '^[A-Za-z]:[\\/]'
    if ($isAbsoluteWindowsPath) {
        return $prefix + (ConvertTo-WslPath -Path $value -MountRoot $MountRoot)
    }

    $isExistingRelativePath = $value.Contains('\') -and (Test-Path -LiteralPath (Join-Path $CurrentFolder $value))
    if ($isExistingRelativePath) {
        return $prefix + $value.Replace('\', '/')
    }

    $Argument
}
