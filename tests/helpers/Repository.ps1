function New-TestRepository {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $ModuleVersion
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $packageScriptPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../scripts/Build-ModulePackage.ps1'))
    $packageFolder = Join-Path ([IO.Path]::GetTempPath()) "winplaybook-package-$([guid]::NewGuid())"
    try {
        & pwsh -NoProfile -Command {
            param($PackageScriptPath, $PackageFolder, $Version, $RepositoryPath)
            $ErrorActionPreference = 'Stop'
            $modulePath = & $PackageScriptPath -Version $Version -Destination $PackageFolder
            Register-PSResourceRepository -Name WinPlaybookPublish -Uri $RepositoryPath -Trusted
            try {
                Publish-PSResource -Path $modulePath -Repository WinPlaybookPublish
            }
            finally {
                Unregister-PSResourceRepository -Name WinPlaybookPublish
            }
        } -args $packageScriptPath, $packageFolder, $ModuleVersion, $Path
        if ($LASTEXITCODE -ne 0) {
            throw "Could not publish the module package to $Path."
        }
    }
    finally {
        Remove-Item -LiteralPath $packageFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    $hasPSResourceGet = [bool] (Get-Command -Name Install-PSResource -ErrorAction SilentlyContinue)
    if ($hasPSResourceGet) {
        Register-PSResourceRepository -Name $Name -Uri $Path
    }
    else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        Register-PSRepository -Name $Name -SourceLocation $Path -InstallationPolicy Untrusted
    }
}

function Remove-TestRepository([string] $Name) {
    $hasPSResourceGet = [bool] (Get-Command -Name Install-PSResource -ErrorAction SilentlyContinue)
    if ($hasPSResourceGet) {
        Unregister-PSResourceRepository -Name $Name
    }
    else {
        Unregister-PSRepository -Name $Name
    }
}
