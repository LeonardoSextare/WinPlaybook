function Invoke-WslCommand {
    <#
    .SYNOPSIS
    Runs a command in the WSL distribution chosen at install, from the current folder.

    .DESCRIPTION
    The command runs in a login shell, which has the folders of the user in the PATH,
    such as ~/.local/bin. The arguments go to the command without a shell reading them.

    A command found only on a Windows drive is refused: WSL adds the Windows Path to the
    distribution, so without Ansible in the distribution a shim would call itself.

    .EXAMPLE
    Invoke-WslCommand -Command 'ansible-playbook' -Arguments 'site.yml'

    Runs ansible-playbook site.yml in the distribution, from the current folder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Command,
        [string[]] $Arguments = @()
    )

    $settings = Get-Setting
    $distribution = $settings.WslDistribution
    $mountRoot = $settings.WslMountRoot

    $isDistributionChosen = [bool] $distribution -and [bool] $mountRoot
    if (-not $isDistributionChosen) {
        throw 'WinPlaybook does not know the WSL distribution that runs Ansible. Choose it with: Install-WinPlaybookShim -Distribution <name> (wsl --list shows the distributions).'
    }

    $isWslInstalled = [bool] (Get-Command -Name wsl -ErrorAction SilentlyContinue)
    if (-not $isWslInstalled) {
        throw 'WSL was not found. WinPlaybook runs Ansible in a WSL distribution: install WSL with wsl --install and try again.'
    }

    $currentFolder = (Get-Location -PSProvider FileSystem).ProviderPath

    # $0 is the mount root and $1 the command.
    $script = @(
        'case $(command -v "$1") in'
        '"") echo "WinPlaybook: $1 was not found in the WSL distribution. Install it there, or run Install-WinPlaybookShim to update the commands." >&2; exit 127 ;;'
        '"$0"*) echo "WinPlaybook: $1 is not in the WSL distribution, only on Windows ($(command -v "$1")). Install it in the distribution." >&2; exit 127 ;;'
        'esac;'
        'exec "$@"'
    ) -join ' '

    $wslArguments = @(
        '--distribution', $distribution
        '--cd', $currentFolder
        '--exec', 'sh', '-lc', $script, $mountRoot
        $Command
    )
    foreach ($argument in $Arguments) {
        $wslArguments += ConvertTo-WslArgument -Argument $argument -MountRoot $mountRoot -CurrentFolder $currentFolder
    }

    $isLegacyArgumentPassing = Test-LegacyArgumentPassing
    if ($isLegacyArgumentPassing) {
        $wslArguments = @(ConvertTo-LegacyNativeArgument -Argument $wslArguments)
    }

    $ErrorActionPreference = 'Continue'
    wsl @wslArguments
}
