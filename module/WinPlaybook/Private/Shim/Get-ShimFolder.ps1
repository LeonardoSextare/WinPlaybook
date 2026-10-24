function Get-ShimFolder {
    <#
    .SYNOPSIS
    Returns the folder of the command shims: the one saved at install, or the default one.

    .EXAMPLE
    Get-ShimFolder

    Returns C:\Users\<user>\AppData\Local\WinPlaybook\bin when the shims are in the default folder.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $savedFolder = (Get-Setting).ShimFolder
    $isInstalled = [bool] $savedFolder
    if ($isInstalled) {
        return $savedFolder
    }

    Join-Path (Get-ConfigFolder) 'bin'
}
