function Get-AnsibleCommand {
    <#
    .SYNOPSIS
    Lists the ansible commands found in the PATH of the image.

    .DESCRIPTION
    Downloads the image first when it is not on this computer yet.

    .EXAMPLE
    Get-AnsibleCommand

    Returns ansible, ansible-config, ansible-lint, ansible-playbook and the other ansible commands.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    Confirm-DockerEngine

    $image = Get-ImageReference
    $ErrorActionPreference = 'Continue'
    
    $null = docker image inspect $image 2>$null

    $isImageMissing = $LASTEXITCODE -ne 0
    if ($isImageMissing) {
        Write-Host "The image $image is not on this computer yet. Downloading it; this can take a few minutes."
        docker pull $image | Out-Host

        $isDownloaded = $LASTEXITCODE -eq 0
        if (-not $isDownloaded) {
            throw "Could not download the image $image (docker exit code $LASTEXITCODE). Check the internet connection and try again."
        }
    }

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
