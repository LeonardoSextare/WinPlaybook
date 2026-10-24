function Remove-Setting {
    <#
    .SYNOPSIS
    Removes the WinPlaybook settings, and the config folder when nothing else is left in it.

    .EXAMPLE
    Remove-Setting
    #>
    [CmdletBinding()]
    param()

    $configFolder = Get-ConfigFolder
    Remove-Item -LiteralPath (Join-Path $configFolder 'settings.json') -ErrorAction SilentlyContinue
    Remove-EmptyFolder -Folder $configFolder
}
