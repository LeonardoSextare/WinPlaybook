# Installs WinPlaybook for the current user, without administrator rights:
#
#     irm https://leonardosextare.github.io/WinPlaybook/install.ps1 | iex
& {
    $ErrorActionPreference = 'Stop'

    $isSupportedVersion = $PSVersionTable.PSVersion -ge [version]'5.1'
    if (-not $isSupportedVersion) {
        throw "WinPlaybook needs Windows PowerShell 5.1 or PowerShell 7. This is PowerShell $($PSVersionTable.PSVersion)."
    }

    $isWindowsPowerShell = $PSVersionTable.PSEdition -eq 'Desktop'
    $isSupportedSystem = $isWindowsPowerShell -or $IsWindows
    if (-not $isSupportedSystem) {
        throw 'WinPlaybook runs only on Windows.'
    }

    $securityProtocol = [Net.ServicePointManager]::SecurityProtocol
    $isSystemDefault = [int] $securityProtocol -eq 0
    $isTls12Missing = $isWindowsPowerShell -and (-not $isSystemDefault) -and ( -not ($securityProtocol -band [Net.SecurityProtocolType]::Tls12))
    if ($isTls12Missing) {
        [Net.ServicePointManager]::SecurityProtocol = $securityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    $executionPolicy = Get-ExecutionPolicy
    $isScriptBlocked = ($executionPolicy -eq 'Restricted') -or ($executionPolicy -eq 'AllSigned')
    if ($isScriptBlocked) {
        $isSetByGroupPolicy = ((Get-ExecutionPolicy -Scope MachinePolicy) -ne 'Undefined') -or ((Get-ExecutionPolicy -Scope UserPolicy) -ne 'Undefined')
        
        if ($isSetByGroupPolicy) {
            throw "A group policy sets the execution policy to $executionPolicy, which blocks the WinPlaybook module. Ask your administrator to allow RemoteSigned scripts."
        }

        $processPolicy = Get-ExecutionPolicy -Scope Process
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    }

    try {
        $repository = 'PSGallery'
        $isRepositoryChosen = [bool] $env:WINPLAYBOOK_REPOSITORY
        if ($isRepositoryChosen) {
            $repository = $env:WINPLAYBOOK_REPOSITORY
        }

        $hasPSResourceGet = [bool] (Get-Command -Name Install-PSResource -ErrorAction SilentlyContinue)
        if ($hasPSResourceGet) {
            $isRepositoryRegistered = [bool] (Get-PSResourceRepository -Name $repository -ErrorAction SilentlyContinue)
            if (-not $isRepositoryRegistered) {
                if ($isRepositoryChosen) {
                    throw "The repository $repository, from the WINPLAYBOOK_REPOSITORY variable, is not registered."
                }
                throw 'The PowerShell Gallery is not registered. Register it with: Register-PSResourceRepository -PSGallery'
            }

            Write-Host "Installing the WinPlaybook module from $repository..."
            Install-PSResource -Name WinPlaybook -Repository $repository -Scope CurrentUser -TrustRepository -Quiet
        }
        else {
            $nugetProvider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
            Where-Object { $_.Version -ge [version]'2.8.5.201' }
            if (-not $nugetProvider) {
                Write-Host 'Installing the NuGet provider that PowerShellGet needs...'
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
            }

            $isRepositoryRegistered = [bool] (Get-PSRepository -Name $repository -ErrorAction SilentlyContinue)
            if (-not $isRepositoryRegistered) {
                if ($isRepositoryChosen) {
                    throw "The repository $repository, from the WINPLAYBOOK_REPOSITORY variable, is not registered."
                }
                throw 'The PowerShell Gallery is not registered. Register it with: Register-PSRepository -Default'
            }

            Write-Host "Installing the WinPlaybook module from $repository..."
            Install-Module -Name WinPlaybook -Repository $repository -Scope CurrentUser -Force
        }

        Remove-Module -Name WinPlaybook -ErrorAction SilentlyContinue
        $module = Import-Module -Name WinPlaybook -PassThru

        try {
            $installation = Install-WinPlaybookShim
        }
        catch {
            Write-Host "WinPlaybook $($module.Version) is installed, but its Ansible commands are not. Fix the problem below and run this installer again." -ForegroundColor Yellow
            throw
        }
    }
    finally {
        if ($isScriptBlocked) {
            Set-ExecutionPolicy -ExecutionPolicy $processPolicy -Scope Process -Force
        }
    }

    Write-Host ''
    Write-Host "WinPlaybook $($module.Version) is installed, with $($installation.Commands.Count) Ansible commands in $($installation.Folder)." -ForegroundColor Green
    Write-Host 'Open a new terminal and try: ansible --version'

    if ($isScriptBlocked) {
        Write-Host ''
        Write-Host "The execution policy $executionPolicy blocks the WinPlaybook module in new terminals. The Ansible commands work anyway. To also use the module commands, such as Install-WinPlaybookShim, run:"
        Write-Host '    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'
    }
}
