function Remove-ShimFolder {
    <#
    .SYNOPSIS
    Removes a shim folder, its WinPlaybook folder when it is left empty, and its user Path entry.

    .EXAMPLE
    Remove-ShimFolder -Folder 'C:\Tools\WinPlaybook\bin'

    Removes C:\Tools\WinPlaybook and keeps C:\Tools.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Folder
    )

    Remove-Item -LiteralPath $Folder -Recurse -Force -ErrorAction SilentlyContinue
    Remove-EmptyFolder -Folder (Split-Path -Path $Folder -Parent)
    Remove-UserPathEntry -Folder $Folder
}
