function Get-UserEnvironmentVariable {
    <#
    .SYNOPSIS
    Returns an environment variable saved for the current user.

    .EXAMPLE
    Get-UserEnvironmentVariable -Name 'Path'

    Returns the Path of the user, without the Path of the machine.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Name
    )

    [Environment]::GetEnvironmentVariable($Name, 'User')
}
