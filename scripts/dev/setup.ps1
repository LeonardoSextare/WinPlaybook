#Requires -Version 7.4

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ============================ Settings ============================
$DOCKER_MIN_VERSION = [version]'23.0'
$UV_MIN_VERSION = [version]'0.11.14'
$REQUIREMENTS_FILE = Join-Path $PSScriptRoot '..\..\requirements.psd1'
$DOCUMENTS_DIR = [Environment]::GetFolderPath('MyDocuments')

# ============================ Functions ============================
function Test-DockerInstalled {
    if (-not (Get-Command 'docker' -ErrorAction SilentlyContinue)) {
        throw 'Docker is not installed or not available in PATH. Install Docker Desktop.'
    }

    $serverVersion = docker info --format '{{.ServerVersion}}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Docker is installed but not responding. Start Docker Desktop.'
    }

    $currentVersion = [version]($serverVersion -replace '[^\d.].*$')
    if ($currentVersion -lt $DOCKER_MIN_VERSION) {
        throw "Docker $currentVersion is older than the minimum required ($DOCKER_MIN_VERSION)."
    }
}

function Test-UvInstalled {
    if (-not (Get-Command 'uv' -ErrorAction SilentlyContinue)) {
        throw 'uv is not installed or not available in PATH. Install it with: winget install astral-sh.uv'
    }

    $currentVersion = [version]((uv --version) -split ' ')[1]
    if ($currentVersion -lt $UV_MIN_VERSION) {
        throw "uv $currentVersion is older than the minimum required ($UV_MIN_VERSION). Update it with: uv self update"
    }
}

function Test-GitInstalled {
    if (-not (Get-Command 'git' -ErrorAction SilentlyContinue)) {
        throw 'git is not installed or not available in PATH. Install it with: winget install Git.Git'
    }
}

function Install-Requirements([string] $ModulesDir) {
    $path = Join-Path $DOCUMENTS_DIR $ModulesDir
    $requirements = Import-PowerShellDataFile $REQUIREMENTS_FILE

    foreach ($name in $requirements.Keys) {
        $spec = $requirements[$name]
        Save-PSResource -Name $name -Version $spec.version -Repository $spec.repository -Path $path -TrustRepository -Quiet
    }
}

# ============================ Execution ============================
Write-Host (('=' * 60) + "`n" + (' ' * 16) + 'WinPlaybook development setup' + "`n" + ('=' * 60)) -ForegroundColor DarkYellow

$steps = @(
    @{ Name = 'Checking Docker'; Action = { Test-DockerInstalled } }
    @{ Name = 'Checking uv'; Action = { Test-UvInstalled } }
    @{ Name = 'Checking git'; Action = { Test-GitInstalled } }
    @{ Name = 'Installing dependencies for PowerShell 7'; Action = { Install-Requirements 'PowerShell\Modules' } }
    @{ Name = 'Installing dependencies for Windows PowerShell'; Action = { Install-Requirements 'WindowsPowerShell\Modules' } }
    @{ Name = 'Downloading the shim packaged with the module'; Action = { & (Join-Path $PSScriptRoot '..\Save-Shim.ps1') } }
    @{ Name = 'Preparing the WSL distribution of the tests'; Action = { & (Join-Path $PSScriptRoot '..\Initialize-TestWslDistribution.ps1') | Out-Null } }
)

for ($i = 0; $i -lt $steps.Count; $i++) {
    $step = $steps[$i]
    Write-Host "[$($i + 1)/$($steps.Count)]" -ForegroundColor DarkCyan -NoNewline
    Write-Host " $($step.Name)..." -NoNewline

    try {
        & $step.Action
        Write-Host ' OK' -ForegroundColor Green
    }
    catch {
        Write-Host ' ERROR' -ForegroundColor Red
        Write-Host "Step $($i + 1) failed: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nSetup finished successfully!" -ForegroundColor Green
