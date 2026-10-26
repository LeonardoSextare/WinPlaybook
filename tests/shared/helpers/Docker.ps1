function Invoke-Docker([string[]] $Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = & docker @Arguments 2>&1 | ForEach-Object { "$_" }
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output -join [Environment]::NewLine
    }
}

function Build-TestImage {
    $image = 'winplaybook:test'
    $imageDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../image'))

    $result = Invoke-Docker @('build', '--quiet', '--tag', $image, $imageDir)
    if ($result.ExitCode -ne 0) {
        throw "Failed to build $image from ${imageDir}: $($result.Output)"
    }
    $image
}

function Invoke-Container {
    param(
        [Parameter(Mandatory)] [string] $Image,
        [string[]] $Command = @(),
        [string] $Project
    )

    $arguments = @('run', '--rm')
    if ($Project) {
        $arguments += '--volume', "${Project}:/work", '--workdir', '/work'
    }
    Invoke-Docker ($arguments + $Image + $Command)
}

function Start-TestContainer([string] $Image) {
    $result = Invoke-Docker @('run', '--detach', '--rm', $Image, 'sleep', 'infinity')
    if ($result.ExitCode -ne 0) {
        throw "Failed to start a container from ${Image}: $($result.Output)"
    }
    $result.Output
}

function Invoke-InContainer {
    param(
        [Parameter(Mandatory)] [string] $Container,
        [Parameter(Mandatory)] [string[]] $Command
    )

    Invoke-Docker (@('exec', $Container) + $Command)
}

function Stop-TestContainer([string] $Container) {
    Invoke-Docker @('rm', '--force', $Container) | Out-Null
}
