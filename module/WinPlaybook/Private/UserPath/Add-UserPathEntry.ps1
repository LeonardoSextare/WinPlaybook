function Add-UserPathEntry {
    <#
    .SYNOPSIS
    Puts a folder at the start of the user Path and of the Path of the current session.

    .DESCRIPTION
    The saved Path reaches the programs started from now on; the session Path makes
    the folder work right away in the current terminal.

    .EXAMPLE
    Add-UserPathEntry -Folder 'C:\shims'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Folder
    )

    $folderEntry = $Folder.TrimEnd('\')

    $userEntries = @("$(Get-UserEnvironmentVariable -Name 'Path')".Split(';') | Where-Object { $_ })
    $isInUserPath = @($userEntries | Where-Object { $_.TrimEnd('\') -eq $folderEntry }).Count -gt 0
    if (-not $isInUserPath) {
        Set-UserEnvironmentVariable -Name 'Path' -Value ((@($Folder) + $userEntries) -join ';')
    }

    $sessionEntries = @("$env:PATH".Split(';') | Where-Object { $_ })
    $isInSessionPath = @($sessionEntries | Where-Object { $_.TrimEnd('\') -eq $folderEntry }).Count -gt 0
    if (-not $isInSessionPath) {
        $env:PATH = (@($Folder) + $sessionEntries) -join ';'
    }
}
