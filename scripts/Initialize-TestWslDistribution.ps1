#Requires -Version 7.4


[CmdletBinding()]
param(
    [string] $WslDistributionName = 'WinPlaybookTest'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# wsl.exe writes UTF-16 by default.
$env:WSL_UTF8 = '1'

$installedNames = wsl --list --quiet
$isInstalled = $installedNames -contains $WslDistributionName
if (-not $isInstalled) {
    wsl --install Ubuntu --name $WslDistributionName --no-launch
}

wsl -d $WslDistributionName -u root -e bash -lc 'command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh'
wsl -d $WslDistributionName -u root -e bash -lc 'uv tool install ansible-core'
wsl -d $WslDistributionName -u root -e bash -lc 'ansible --version'
