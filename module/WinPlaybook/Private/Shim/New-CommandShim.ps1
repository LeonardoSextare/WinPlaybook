function New-CommandShim {
    <#
    .SYNOPSIS
    Creates the .ps1, .exe and .shim files that make a command of the container available on Windows.

    .DESCRIPTION
    PowerShell runs the .ps1 in its own process. Other programs run the .exe, a copy of
    the packaged shim, which starts the chosen PowerShell with the same .ps1.

    .EXAMPLE
    New-CommandShim -Name 'ansible-playbook' -Folder 'C:\shims' -PowerShellPath 'C:\Program Files\PowerShell\7\pwsh.exe'

    Creates ansible-playbook.ps1, ansible-playbook.exe and ansible-playbook.shim in C:\shims.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Folder,
        [Parameter(Mandatory)] [string] $PowerShellPath
    )

    $scriptPath = Join-Path $Folder "$Name.ps1"
    Set-Content -LiteralPath $scriptPath -Value "WinPlaybook\Invoke-WinPlaybook '$Name' @args" -Encoding UTF8

    Copy-Item -LiteralPath (Get-ShimTemplatePath) -Destination (Join-Path $Folder "$Name.exe") -Force

    Set-Content -LiteralPath (Join-Path $Folder "$Name.shim") -Encoding UTF8 -Value @(
        "path = $PowerShellPath"
        "args = -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    )
}
