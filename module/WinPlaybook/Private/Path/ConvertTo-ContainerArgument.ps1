function ConvertTo-ContainerArgument {
    <#
    .SYNOPSIS
    Converts a Windows path in a command argument to its path in the container.

    .DESCRIPTION
    An absolute path inside the project becomes a path under /work. A relative path
    with backslashes gets forward slashes, but only when it exists: other arguments
    may contain backslashes that are not paths. The path can come after an option
    (--inventory=) and after @, as in -e @vars\prod.yml.

    .EXAMPLE
    ConvertTo-ContainerArgument -Argument '.\site.yml' -ProjectRoot 'C:\repo' -CurrentFolder 'C:\repo'

    Returns ./site.yml.

    .EXAMPLE
    ConvertTo-ContainerArgument -Argument '--inventory=C:\repo\hosts.yml' -ProjectRoot 'C:\repo' -CurrentFolder 'C:\repo'

    Returns --inventory=/work/hosts.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Argument,
        [Parameter(Mandatory)] [string] $ProjectRoot,
        [Parameter(Mandatory)] [string] $CurrentFolder
    )

    $null = $Argument -match '^(?<prefix>(--[\w-]+=)?@?)(?<value>.*)$'
    $prefix = $Matches.prefix
    $value = $Matches.value

    $isAbsoluteWindowsPath = $value -match '^[A-Za-z]:[\\/]'
    if ($isAbsoluteWindowsPath) {
        return $prefix + (ConvertTo-ContainerPath -Path $value -Root $ProjectRoot)
    }

    $isExistingRelativePath = $value.Contains('\') -and (Test-Path -LiteralPath (Join-Path $CurrentFolder $value))
    if ($isExistingRelativePath) {
        return $prefix + $value.Replace('\', '/')
    }

    $Argument
}
