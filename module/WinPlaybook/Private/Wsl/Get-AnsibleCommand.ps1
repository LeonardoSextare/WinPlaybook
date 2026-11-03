function Get-AnsibleCommand {
    <#
    .SYNOPSIS
    Lists the ansible commands found in the PATH of a WSL distribution.

    .DESCRIPTION
    Reads the PATH of a login shell, which has the folders of the user, such as
    ~/.local/bin. The folders of the Windows drives are skipped: WSL adds the Windows
    Path to the distribution, and it has the WinPlaybook shims.

    .EXAMPLE
    Get-AnsibleCommand -Distribution 'Ubuntu' -MountRoot '/mnt/'

    Returns ansible, ansible-config, ansible-lint, ansible-playbook and the other ansible commands.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string] $Distribution,
        [Parameter(Mandatory)] [string] $MountRoot
    )

    # $0 is the mount root.
    $script = 'IFS=:; for folder in $PATH; do case $folder in "$0"*) ;; *) ls "$folder" 2>/dev/null || : ;; esac; done'
    $wslArguments = @('--distribution', $Distribution, '--exec', 'sh', '-lc', $script, $MountRoot)

    $isLegacyArgumentPassing = Test-LegacyArgumentPassing
    if ($isLegacyArgumentPassing) {
        $wslArguments = @(ConvertTo-LegacyNativeArgument -Argument $wslArguments)
    }

    $ErrorActionPreference = 'Continue'
    $listing = wsl @wslArguments

    $isListed = $LASTEXITCODE -eq 0
    if (-not $isListed) {
        throw "Could not list the commands of the WSL distribution $Distribution (wsl exit code $LASTEXITCODE)."
    }

    $commands = @($listing | Where-Object { $_.StartsWith('ansible') } | Sort-Object -Unique)

    $hasCommands = $commands.Count -gt 0
    if (-not $hasCommands) {
        throw "The WSL distribution $Distribution has no ansible commands. Install Ansible in it and try again."
    }

    $commands
}
