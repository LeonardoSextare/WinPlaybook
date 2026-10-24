function Get-ShimTemplatePath {
    <#
    .SYNOPSIS
    Returns the path of the shim.exe packaged with the module, copied for each command.

    .EXAMPLE
    Get-ShimTemplatePath

    Returns <module folder>\bin\shim.exe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $templatePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\bin\shim.exe'))

    $isPackaged = Test-Path -LiteralPath $templatePath
    if (-not $isPackaged) {
        throw "shim.exe is missing at $templatePath. Reinstall WinPlaybook, or run scripts/Save-Shim.ps1 in a clone of the repository."
    }

    $templatePath
}
