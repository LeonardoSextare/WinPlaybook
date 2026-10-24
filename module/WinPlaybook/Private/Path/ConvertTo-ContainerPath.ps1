function ConvertTo-ContainerPath {
    <#
    .SYNOPSIS
    Converts a Windows path inside the project root to its path in the container.

    .EXAMPLE
    ConvertTo-ContainerPath -Path 'C:\repo\playbooks\site.yml' -Root 'C:\repo'

    Returns /work/playbooks/site.yml.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Root
    )

    $windowsPath = $Path.Replace('/', '\').TrimEnd('\')
    $projectRoot = $Root.Replace('/', '\').TrimEnd('\')

    $isProjectRoot = $windowsPath -eq $projectRoot
    if ($isProjectRoot) {
        return '/work'
    }

    $rootWithSeparator = $projectRoot + '\'
    $isInsideProject = $windowsPath.StartsWith($rootWithSeparator, [StringComparison]::OrdinalIgnoreCase)
    if (-not $isInsideProject) {
        throw "The path '$Path' is outside the project root '$Root' and is not available inside the container."
    }

    $relativePath = $windowsPath.Substring($rootWithSeparator.Length)
    '/work/' + $relativePath.Replace('\', '/')
}
