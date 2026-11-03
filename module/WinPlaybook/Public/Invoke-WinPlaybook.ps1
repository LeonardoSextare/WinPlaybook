function Invoke-WinPlaybook {
    <#
    .SYNOPSIS
    Runs a command in the WSL distribution chosen at install, from the current folder.

    .DESCRIPTION
    The first argument is the command; every other argument goes to it unchanged,
    except Windows paths, which become their paths in the distribution.

    This is a simple function on purpose. With [CmdletBinding()], PowerShell would
    read Ansible options such as -i as its own parameters.

    .EXAMPLE
    Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml

    Runs the playbook in the WSL distribution.
    #>

    $hasCommand = $args.Count -gt 0
    if (-not $hasCommand) {
        throw 'Specify the command to run in the WSL distribution, for example: Invoke-WinPlaybook ansible --version'
    }

    Invoke-WslCommand -Command $args[0] -Arguments @($args | Select-Object -Skip 1)
}
