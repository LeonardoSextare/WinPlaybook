function Confirm-DockerEngine {
    <#
    .SYNOPSIS
    Stops with a clear message when Docker is not installed or its engine is not running.

    .EXAMPLE
    Confirm-DockerEngine

    Returns nothing when Docker can run containers; otherwise, throws.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $isDockerInstalled = [bool] (Get-Command -Name docker -ErrorAction SilentlyContinue)
    if (-not $isDockerInstalled) {
        throw 'Docker was not found. WinPlaybook runs Ansible in a Docker container: install Docker Desktop (https://docs.docker.com/desktop/setup/install/windows-install/) and try again.'
    }

    $ErrorActionPreference = 'Continue'
    $null = docker version --format '{{.Server.Version}}' 2>$null

    $isEngineRunning = $LASTEXITCODE -eq 0
    if (-not $isEngineRunning) {
        throw 'Docker is installed, but its engine is not responding. Start Docker Desktop and try again.'
    }
}
