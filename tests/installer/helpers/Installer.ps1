function Invoke-Installer([string] $ExecutionPolicy) {
    $installerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../installer/install.ps1'))
    $command = @'
try {
    Get-Content -Raw -LiteralPath 'INSTALLER_PATH' | Invoke-Expression
}
catch {
    "InstallerError=$($_.Exception.Message)"
    exit 1
}
"ProcessPolicy=$(Get-ExecutionPolicy -Scope Process)"
'@
    Invoke-PowerShellProcess -Command $command.Replace('INSTALLER_PATH', $installerPath) -ExecutionPolicy $ExecutionPolicy
}

function Uninstall-TestInstallation {
    $command = @'
try { Uninstall-WinPlaybookShim } catch {}
if (Get-Command -Name Uninstall-PSResource -ErrorAction SilentlyContinue) {
    Uninstall-PSResource -Name WinPlaybook -Scope CurrentUser
}
else {
    Uninstall-Module -Name WinPlaybook -AllVersions
}
'@
    Invoke-PowerShellProcess -Command $command | Out-Null
}
