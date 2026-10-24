function Get-PackagedShimPath {
    $shimPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../module/WinPlaybook/bin/shim.exe'))
    if (-not (Test-Path -LiteralPath $shimPath)) {
        throw "shim.exe not found at $shimPath. Run scripts/Save-Shim.ps1 first."
    }
    $shimPath
}

function New-TestShim([string] $Folder, [string] $Name, [string] $TargetPath, [string] $TargetArguments) {
    $exePath = Join-Path $Folder "$Name.exe"
    Copy-Item -LiteralPath (Get-PackagedShimPath) -Destination $exePath
    Set-Content -LiteralPath (Join-Path $Folder "$Name.shim") -Value @(
        "path = $TargetPath"
        "args = $TargetArguments"
    )
    $exePath
}
