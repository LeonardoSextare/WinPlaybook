BeforeAll {
    . (Join-Path $PSScriptRoot '../../shared/helpers/Docker.ps1')
    . (Join-Path $PSScriptRoot '../../shared/helpers/Process.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Installer.ps1')
    . (Join-Path $PSScriptRoot '../helpers/Repository.ps1')
}

Describe 'install.ps1' -Skip:(-not $env:CI) {
    BeforeAll {
        $originalImage = $env:WINPLAYBOOK_IMAGE
        $originalRepository = $env:WINPLAYBOOK_REPOSITORY
        $env:WINPLAYBOOK_IMAGE = Build-TestImage

        $repositoryName = 'WinPlaybookTest'
        New-TestRepository -Name $repositoryName -Path (Join-Path $TestDrive 'repository') -ModuleVersion 0.0.1
        $env:WINPLAYBOOK_REPOSITORY = $repositoryName
    }

    AfterAll {
        $uninstallCommand = @'
try { Uninstall-WinPlaybookShim } catch {}
if (Get-Command -Name Uninstall-PSResource -ErrorAction SilentlyContinue) {
    Uninstall-PSResource -Name WinPlaybook -Scope CurrentUser
}
else {
    Uninstall-Module -Name WinPlaybook -AllVersions
}
'@
        Invoke-PowerShellProcess -Command $uninstallCommand | Out-Null

        Remove-TestRepository -Name $repositoryName
        $env:WINPLAYBOOK_REPOSITORY = $originalRepository
        $env:WINPLAYBOOK_IMAGE = $originalImage
    }

    Context 'when it installs from a registered repository' {
        BeforeAll {
            $result = Invoke-Installer
        }

        It 'finishes without asking anything' {
            $result.ExitCode | Should-Be 0 -Because "$($result.Output)`n$($result.Error)"
        }

        It 'installs the module of the repository' {
            $result.Output | Should-BeLikeString '*WinPlaybook 0.0.1 is installed*' -Because $result.Error
        }

        It 'makes the Ansible commands work' {
            $commandResult = Invoke-CommandLine -FilePath (Join-Path $env:LOCALAPPDATA 'WinPlaybook/bin/ansible.exe') -ArgumentList '--version'

            $commandResult.ExitCode | Should-Be 0 -Because "$($commandResult.Output)`n$($commandResult.Error)"
            $commandResult.Output | Should-BeLikeString 'ansible `[core*'
        }
    }

    Context 'when the execution policy blocks scripts' {
        BeforeAll {
            $result = Invoke-Installer -ExecutionPolicy Restricted
        }

        It 'installs anyway' {
            $result.ExitCode | Should-Be 0 -Because "$($result.Output)`n$($result.Error)"
        }

        It 'explains how to allow the module commands' {
            $result.Output | Should-BeLikeString '*Set-ExecutionPolicy RemoteSigned -Scope CurrentUser*' -Because $result.Error
        }

        It 'restores the execution policy of the terminal' {
            $result.Output | Should-BeLikeString '*ProcessPolicy=Restricted' -Because $result.Error
        }
    }

    Context 'when WINPLAYBOOK_REPOSITORY names a repository that is not registered' {
        BeforeAll {
            $env:WINPLAYBOOK_REPOSITORY = 'WinPlaybookMissing'
            $result = Invoke-Installer
            $env:WINPLAYBOOK_REPOSITORY = $repositoryName
        }

        It 'fails' {
            $result.ExitCode | Should-Be 1 -Because "$($result.Output)`n$($result.Error)"
        }

        It 'names the repository and the variable' {
            $result.Output | Should-BeLikeString '*InstallerError=The repository WinPlaybookMissing, from the WINPLAYBOOK_REPOSITORY variable,*' -Because $result.Error
        }
    }
}
