function Get-AnsibleCommand {
    <#
    .SYNOPSIS
    Lists the ansible commands found in the PATH of the image.

    .EXAMPLE
    Get-AnsibleCommand

    Returns ansible, ansible-config, ansible-lint, ansible-playbook and the other ansible commands.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $image = Get-ImageReference
    # No double quotes in the script: Windows PowerShell 5.1 drops them when calling docker.
    $listing = docker run --rm $image sh -c 'IFS=:; for folder in $PATH; do ls $folder 2>/dev/null; done'

    $isListed = $LASTEXITCODE -eq 0
    if (-not $isListed) {
        throw "Could not list the commands of the image $image (docker exit code $LASTEXITCODE)."
    }

    $commands = @($listing | Where-Object { $_.StartsWith('ansible') } | Sort-Object -Unique)

    $hasCommands = $commands.Count -gt 0
    if (-not $hasCommands) {
        throw "The image $image has no ansible commands. Check the WINPLAYBOOK_IMAGE variable."
    }

    $commands
}
