function Uninstall-WinPlaybookShim {
    <#
    .SYNOPSIS
    Removes the command shims created by Install-WinPlaybookShim, and their folder from the user Path.

    .EXAMPLE
    Uninstall-WinPlaybookShim
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $shimFolder = Get-ShimFolder
    $isConfirmed = $PSCmdlet.ShouldProcess($shimFolder, 'Remove the WinPlaybook command shims')
    if (-not $isConfirmed) {
        return
    }

    Remove-ShimFolder -Folder $shimFolder
    Remove-Setting
}
