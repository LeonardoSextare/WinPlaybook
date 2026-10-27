function Get-AnsibleHome {
    <#
    .SYNOPSIS
    Returns the Windows folder that the container uses as ~/.ansible.

    .DESCRIPTION
    It's the folder that Ansible uses on Linux, in the user folder. The collections
    and roles that ansible-galaxy installs stay there between runs.

    .EXAMPLE
    Get-AnsibleHome

    Returns C:\Users\<user>\.ansible.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path $env:USERPROFILE '.ansible'
}
