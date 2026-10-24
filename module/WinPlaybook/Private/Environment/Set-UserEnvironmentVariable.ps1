function Set-UserEnvironmentVariable {
    <#
    .SYNOPSIS
    Saves an environment variable for the current user, or removes it when the value is empty.

    .EXAMPLE
    Set-UserEnvironmentVariable -Name 'Path' -Value 'C:\shims;C:\tools'

    Programs started from now on see the new Path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [string] $Value
    )

    $isRemoval = -not $Value
    if ($isRemoval) {
        # PowerShell turns $null into an empty string when calling .NET, and PowerShell 7
        # saves an empty string instead of removing the variable. NullString passes a real null.
        [Environment]::SetEnvironmentVariable($Name, [NullString]::Value, 'User')
        return
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
}
