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
        '--workdir', $workingDirectory
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

    docker @dockerArguments
}
