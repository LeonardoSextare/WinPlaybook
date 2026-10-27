function Get-AnsibleHome {
    <#
    .SYNOPSIS
    Returns the Windows folder that the container uses as ~/.ansible.

    .DESCRIPTION
    It's the folder that Ansible uses on Linux, in the user folder. The collections
    and roles that ansible-galaxy installs stay there between runs.

    The WINPLAYBOOK_ANSIBLE_HOME environment variable replaces the folder, so the
    tests don't change the folder of the user.

    .EXAMPLE
    Get-AnsibleHome

    Returns C:\Users\<user>\.ansible when WINPLAYBOOK_ANSIBLE_HOME is not set.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $isFolderOverridden = [bool] $env:WINPLAYBOOK_ANSIBLE_HOME
    if ($isFolderOverridden) {
        return $env:WINPLAYBOOK_ANSIBLE_HOME
    }

    Join-Path $env:USERPROFILE '.ansible'
}
