function Invoke-WinPlaybook {
    <#
    .SYNOPSIS
    Runs a command in the WinPlaybook container, from the current folder.

    .DESCRIPTION
    The first argument is the command; every other argument goes to it unchanged.

    This is a simple function on purpose. With [CmdletBinding()], PowerShell would
    read Ansible options such as -i as its own parameters.

    .EXAMPLE
    Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml

    Runs the playbook in the container.
    #>

    $hasCommand = $args.Count -gt 0
    if (-not $hasCommand) {
        throw 'Specify the command to run in the container, for example: Invoke-WinPlaybook ansible --version'
    }

    Invoke-AnsibleContainer -Command $args[0] -Arguments @($args | Select-Object -Skip 1)
}
