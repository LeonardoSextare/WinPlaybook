function Build-TestImage {
    $image = 'winplaybook:test'
    $imageDir = Join-Path $PSScriptRoot '..\..\image'

    docker build --quiet --tag $image $imageDir | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build $image from $imageDir."
    }
    $image
}

function Invoke-Container {
    param(
        [Parameter(Mandatory)] [string] $Image,
        [string[]] $Command = @(),
        [string] $Project
    )

    $ErrorActionPreference = 'Continue'
    $arguments = @('run', '--rm')
    if ($Project) {
        $arguments += '--volume', "${Project}:/work", '--workdir', '/work'
    }

    $output = & docker @arguments $Image @Command 2>&1 | ForEach-Object { "$_" }
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output -join [Environment]::NewLine
    }
}
