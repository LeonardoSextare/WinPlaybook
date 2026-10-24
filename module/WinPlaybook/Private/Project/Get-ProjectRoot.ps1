function Get-ProjectRoot {
    <#
    .SYNOPSIS
    Returns the root of the git repository that contains a folder, or the folder itself.

    .EXAMPLE
    Get-ProjectRoot -Path 'C:\repo\playbooks'

    Returns C:\repo when C:\repo has a .git folder or file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Path
    )

    $currentFolder = $Path
    while ($currentFolder) {
        $isRepositoryRoot = Test-Path -LiteralPath (Join-Path $currentFolder '.git')
        if ($isRepositoryRoot) {
            return $currentFolder
        }

        $currentFolder = Split-Path -Path $currentFolder -Parent
    }

    $Path
}
