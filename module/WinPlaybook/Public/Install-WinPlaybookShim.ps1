function Install-WinPlaybookShim {
    <#
    .SYNOPSIS
    Makes the Ansible commands of the image, such as ansible-playbook, available as Windows commands.

    .DESCRIPTION
    For each ansible command in the image, creates a .ps1 that PowerShell runs and an .exe
    that other programs run, and puts their folder in the user Path. The folder belongs to
    WinPlaybook: installing again replaces everything in it, and uninstalling removes it.

    .PARAMETER Path
    The folder where the WinPlaybook folder is created; the shims go to <Path>\WinPlaybook\bin.
    By default, they go to %LOCALAPPDATA%\WinPlaybook\bin.

    .PARAMETER PowerShell
    The PowerShell that the .exe shims start: Desktop (Windows PowerShell 5.1, which starts
    faster) or Core (PowerShell 7). By default, the one chosen in the previous install, or
    the PowerShell that runs this command on the first install.

    .EXAMPLE
    Install-WinPlaybookShim

    .EXAMPLE
    Install-WinPlaybookShim -Path 'C:\Tools' -PowerShell Desktop

    Creates the shims in C:\Tools\WinPlaybook\bin, started by Windows PowerShell 5.1.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
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

    $isConfirmed = $PSCmdlet.ShouldProcess($shimFolder, 'Install the WinPlaybook command shims')
    if (-not $isConfirmed) {
        return
    }

    $commands = Get-AnsibleCommand

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
    Save-Setting -Settings @{ ShimFolder = $shimFolder; ShimPowerShellPath = $powerShellPath }

    foreach ($command in $commands) {
        New-CommandShim -Name $command -Folder $shimFolder -PowerShellPath $powerShellPath
    }
    Add-UserPathEntry -Folder $shimFolder

    [pscustomobject]@{
        Folder   = $shimFolder
        Commands = $commands
    }
}
