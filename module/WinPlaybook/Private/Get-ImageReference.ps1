function Get-ImageReference {
    <#
    .SYNOPSIS
    Returns the Docker image that runs the Ansible commands.

    .DESCRIPTION
    The WINPLAYBOOK_IMAGE environment variable replaces the published image,
    for example to pin a version or to test an image built locally.

    .EXAMPLE
    Get-ImageReference

    Returns ghcr.io/leonardosextare/winplaybook:0 when WINPLAYBOOK_IMAGE is not set.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $isImageOverridden = [bool] $env:WINPLAYBOOK_IMAGE
    if ($isImageOverridden) {
        return $env:WINPLAYBOOK_IMAGE
    }

    'ghcr.io/leonardosextare/winplaybook:0'
}
