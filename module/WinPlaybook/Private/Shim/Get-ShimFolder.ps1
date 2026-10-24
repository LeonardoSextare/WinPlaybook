function Get-ShimFolder {
    <#
    .SYNOPSIS
    Returns the folder where the command shims are created.

    .EXAMPLE
    Get-ShimFolder

    Returns C:\Users\<user>\AppData\Local\WinPlaybook\bin.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path (Join-Path $env:LOCALAPPDATA 'WinPlaybook') 'bin'
}
