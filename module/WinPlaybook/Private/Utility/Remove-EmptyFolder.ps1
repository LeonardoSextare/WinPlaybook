function Remove-EmptyFolder {
    <#
    .SYNOPSIS
    Removes a folder only when it is empty.

    .EXAMPLE
    Remove-EmptyFolder -Folder 'C:\Tools\WinPlaybook'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Folder
    )

    $isEmptyFolder = (Test-Path -LiteralPath $Folder) -and -not (Get-ChildItem -LiteralPath $Folder -Force | Select-Object -First 1)
    if ($isEmptyFolder) {
        Remove-Item -LiteralPath $Folder
    }
}
