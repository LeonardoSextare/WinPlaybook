function Install-WinPlaybookShim {
    <#
    .SYNOPSIS
    Makes the Ansible commands of a WSL distribution, such as ansible-playbook, available as Windows commands.

    .DESCRIPTION
    For each ansible command in the distribution, creates a .ps1 that PowerShell runs and an
    .exe that other programs run, and puts their folder in the user Path. The folder belongs
    to WinPlaybook: installing again replaces everything in it, and uninstalling removes it.

    Install again after you install or remove Ansible commands in the distribution.

    .PARAMETER Distribution
    The WSL distribution where Ansible is installed, as wsl --list shows it. Required on the
    first install; later, by default, the one chosen in the previous install.

    .PARAMETER Path
    The folder where the WinPlaybook folder is created; the shims go to <Path>\WinPlaybook\bin.
    By default, they go to %LOCALAPPDATA%\WinPlaybook\bin.

    .PARAMETER PowerShell
    The PowerShell that the .exe shims start: Desktop (Windows PowerShell 5.1, which starts
    faster) or Core (PowerShell 7). By default, the one chosen in the previous install, or
    the PowerShell that runs this command on the first install.

    .EXAMPLE
    Install-WinPlaybookShim -Distribution Ubuntu

    .EXAMPLE
    Install-WinPlaybookShim -Path 'C:\Tools' -PowerShell Desktop

    Creates the shims in C:\Tools\WinPlaybook\bin, started by Windows PowerShell 5.1, for
    the distribution chosen in the previous install.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [string] $Distribution,
        [string] $Path,
        [ValidateSet('Desktop', 'Core')] [string] $PowerShell
    )

    $shimFolder = Join-Path (Get-ConfigFolder) 'bin'
    $isPathChosen = [bool] $Path
    if ($isPathChosen) {
        $shimFolder = Join-Path $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path) 'WinPlaybook\bin'
    }

    $settings = Get-Setting
    $previousShimFolder = $settings.ShimFolder
    $isOwnFolder = $previousShimFolder -eq $shimFolder
    $isForeignFolder = (Test-Path -LiteralPath $shimFolder) -and -not $isOwnFolder
    if ($isForeignFolder) {
        throw "The folder $shimFolder already exists and was not created by WinPlaybook. Choose another -Path, or remove the folder."
    }

    $wslDistribution = $settings.WslDistribution
    $isDistributionChosen = [bool] $Distribution
    if ($isDistributionChosen) {
        $wslDistribution = $Distribution
    }

    if (-not $wslDistribution) {
        throw 'Choose the WSL distribution where Ansible is installed: Install-WinPlaybookShim -Distribution <name> (wsl --list shows the distributions).'
    }

    $isConfirmed = $PSCmdlet.ShouldProcess($shimFolder, 'Install the WinPlaybook command shims')
    if (-not $isConfirmed) {
        return
    }

    $isInstalledDistribution = $wslDistribution -in @(Get-WslDistribution)
    if (-not $isInstalledDistribution) {
        throw "The WSL distribution $wslDistribution does not exist. Choose one that wsl --list shows."
    }

    $mountRoot = Get-WslMountRoot -Distribution $wslDistribution
    $commands = Get-AnsibleCommand -Distribution $wslDistribution -MountRoot $mountRoot

    $powerShellPath = $settings.ShimPowerShellPath
    $isEditionChosen = [bool] $PowerShell
    if ($isEditionChosen) {
        $powerShellPath = Get-PowerShellPath -Edition $PowerShell
    }

    $isPowerShellAvailable = $powerShellPath -and (Test-Path -LiteralPath $powerShellPath)
    if (-not $isPowerShellAvailable) {
        $powerShellPath = Get-PowerShellPath
    }

    $isMoving = $previousShimFolder -and -not $isOwnFolder
    if ($isMoving) {
        Remove-ShimFolder -Folder $previousShimFolder
    }

    Remove-Item -LiteralPath $shimFolder -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $shimFolder -Force | Out-Null
    Save-Setting -Settings @{
        ShimFolder         = $shimFolder
        ShimPowerShellPath = $powerShellPath
        WslDistribution    = $wslDistribution
        WslMountRoot       = $mountRoot
    }

    foreach ($command in $commands) {
        New-CommandShim -Name $command -Folder $shimFolder -PowerShellPath $powerShellPath
    }
    Add-UserPathEntry -Folder $shimFolder

    [pscustomobject]@{
        Folder       = $shimFolder
        Distribution = $wslDistribution
        Commands     = $commands
    }
}
