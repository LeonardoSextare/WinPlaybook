function Remove-UserPathEntry {
    <#
    .SYNOPSIS
    Removes a folder from the user Path and from the Path of the current session.

    .EXAMPLE
    Remove-UserPathEntry -Folder 'C:\shims'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Folder
    )

    $folderEntry = $Folder.TrimEnd('\')

    $userEntries = @("$(Get-UserEnvironmentVariable -Name 'Path')".Split(';') | Where-Object { $_ })
    $remainingUserEntries = @($userEntries | Where-Object { $_.TrimEnd('\') -ne $folderEntry })
    $isInUserPath = $remainingUserEntries.Count -lt $userEntries.Count
    if ($isInUserPath) {
        Set-UserEnvironmentVariable -Name 'Path' -Value ($remainingUserEntries -join ';')
    }

    $sessionEntries = @("$env:PATH".Split(';') | Where-Object { $_ })
    $remainingSessionEntries = @($sessionEntries | Where-Object { $_.TrimEnd('\') -ne $folderEntry })
    $env:PATH = $remainingSessionEntries -join ';'
}
