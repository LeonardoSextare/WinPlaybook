function Get-ConfigFolder {
    <#
    .SYNOPSIS
    Returns the folder where WinPlaybook keeps its settings.

    .DESCRIPTION
    The location is fixed, so every command finds the settings without knowing where
    the shims were installed.

    .EXAMPLE
    Get-ConfigFolder

    Returns C:\Users\<user>\AppData\Local\WinPlaybook.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path $env:LOCALAPPDATA 'WinPlaybook'
}
