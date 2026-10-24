function Save-Setting {
    <#
    .SYNOPSIS
    Saves the WinPlaybook settings as JSON in the config folder.

    .EXAMPLE
    Save-Setting -Settings @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = 'C:\Program Files\PowerShell\7\pwsh.exe' }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable] $Settings
    )

    $configFolder = Get-ConfigFolder
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
    $Settings | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Encoding UTF8
}
