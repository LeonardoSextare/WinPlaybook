function Invoke-AnsibleContainer {
    <#
    .SYNOPSIS
    Runs a command in a new container, with the project of the current folder mounted at /work.

    .EXAMPLE
    Invoke-AnsibleContainer -Command 'ansible-playbook' -Arguments 'site.yml'

    Runs ansible-playbook site.yml in the container, from the current folder of the project.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Command,
        [string[]] $Arguments = @()
    )

    Confirm-DockerEngine

    $currentFolder = (Get-Location -PSProvider FileSystem).ProviderPath
    $projectRoot = Get-ProjectRoot -Path $currentFolder
    $workingDirectory = ConvertTo-ContainerPath -Path $currentFolder -Root $projectRoot

    $dockerArguments = @('run', '--rm', '--interactive')

    $isInteractiveTerminal = Test-InteractiveTerminal
    if ($isInteractiveTerminal) {
        $dockerArguments += '--tty'
    }

    $dockerArguments += @(
        '--volume', "${projectRoot}:/work"
        '--volume', "$(Get-AnsibleHome):/root/.ansible"
        '--workdir', $workingDirectory
    )

    $projectConfigPath = Join-Path $currentFolder 'ansible.cfg'
    $isProjectConfigPresent = Test-Path -LiteralPath $projectConfigPath -PathType Leaf
    if ($isProjectConfigPresent) {
        $dockerArguments += '--env', "ANSIBLE_CONFIG=$workingDirectory/ansible.cfg"
    }

    $userConfigPath = Join-Path $env:USERPROFILE '.ansible.cfg'
    $isUserConfigPresent = Test-Path -LiteralPath $userConfigPath -PathType Leaf
    if ($isUserConfigPresent) {
        $dockerArguments += '--volume', "${userConfigPath}:/root/.ansible.cfg"
    }

    $dockerArguments += @(
        (Get-ImageReference)
        $Command
    )
    foreach ($argument in $Arguments) {
        $dockerArguments += ConvertTo-ContainerArgument -Argument $argument -ProjectRoot $projectRoot -CurrentFolder $currentFolder
    }

    $isLegacyArgumentPassing = Test-LegacyArgumentPassing
    if ($isLegacyArgumentPassing) {
        $dockerArguments = @(ConvertTo-LegacyNativeArgument -Argument $dockerArguments)
    }

    $ErrorActionPreference = 'Continue'
    docker @dockerArguments
}
