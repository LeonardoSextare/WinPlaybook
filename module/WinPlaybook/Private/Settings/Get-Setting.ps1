function Get-Setting {
    <#
    .SYNOPSIS
    Returns the WinPlaybook settings, with empty values when nothing was saved yet.

    .EXAMPLE
    (Get-Setting).ShimFolder

    Returns the folder where the shims were installed, or $null.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $settings = @{
        ShimFolder         = $null
        ShimPowerShellPath = $null
    }

    $settingsPath = Join-Path (Get-ConfigFolder) 'settings.json'
    $hasSettingsFile = Test-Path -LiteralPath $settingsPath
    if (-not $hasSettingsFile) {
        return $settings
    }

    $savedSettings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    foreach ($property in $savedSettings.PSObject.Properties) {
        $settings[$property.Name] = $property.Value
    }

    $settings
}
