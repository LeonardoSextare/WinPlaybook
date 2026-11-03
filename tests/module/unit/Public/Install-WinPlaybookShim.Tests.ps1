BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-WinPlaybookShim' {
    BeforeAll {
        $templatePath = Join-Path $TestDrive 'template.exe'
        Set-Content -LiteralPath $templatePath -Value 'template shim'

        Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }
        Mock Get-ShimTemplatePath -ModuleName WinPlaybook { $templatePath }
        Mock Get-WslDistribution -ModuleName WinPlaybook { 'Ubuntu', 'Debian' }
        Mock Get-WslMountRoot -ModuleName WinPlaybook { '/mnt/' }
        Mock Get-AnsibleCommand -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        $currentPowerShellPath = Join-Path $TestDrive 'current/pwsh.exe'
        $desktopPowerShellPath = Join-Path $TestDrive 'desktop/powershell.exe'
        New-Item -ItemType File -Path $currentPowerShellPath, $desktopPowerShellPath -Force | Out-Null
        Mock Get-PowerShellPath -ModuleName WinPlaybook { $currentPowerShellPath }
        Mock Get-PowerShellPath -ModuleName WinPlaybook -ParameterFilter { $Edition -eq 'Desktop' } { $desktopPowerShellPath }

        Mock Add-UserPathEntry -ModuleName WinPlaybook { }
        Mock Remove-UserPathEntry -ModuleName WinPlaybook { }

        function Get-SavedSetting {
            Get-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Raw | ConvertFrom-Json
        }
    }

    BeforeEach {
        $configFolder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $defaultShimFolder = Join-Path $configFolder 'bin'
    }

    Context 'when installing in the default folder' {
        It 'creates a shim for each command of the distribution' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            (Get-ChildItem -LiteralPath $defaultShimFolder -Filter '*.ps1').BaseName | Should-BeCollection @('ansible', 'ansible-playbook')
        }

        It 'puts the shim folder in the user Path' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            Should-Invoke Add-UserPathEntry -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Folder -eq $defaultShimFolder
            }
        }

        It 'saves the shim folder in the settings' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            (Get-SavedSetting).ShimFolder | Should-Be $defaultShimFolder
        }

        It 'returns the shim folder' {
            $result = Install-WinPlaybookShim -Distribution 'Ubuntu'

            $result.Folder | Should-Be $defaultShimFolder
        }
    }

    Context 'when a distribution is chosen' {
        It 'creates the shims from the commands of that distribution' {
            Install-WinPlaybookShim -Distribution 'Debian' | Out-Null

            Should-Invoke Get-AnsibleCommand -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Distribution -eq 'Debian' -and $MountRoot -eq '/mnt/'
            }
        }

        It 'saves the distribution in the settings' {
            Install-WinPlaybookShim -Distribution 'Debian' | Out-Null

            (Get-SavedSetting).WslDistribution | Should-Be 'Debian'
        }

        It 'saves where the distribution mounts the Windows drives' {
            Install-WinPlaybookShim -Distribution 'Debian' | Out-Null

            (Get-SavedSetting).WslMountRoot | Should-Be '/mnt/'
        }

        It 'returns the distribution' {
            $result = Install-WinPlaybookShim -Distribution 'Debian'

            $result.Distribution | Should-Be 'Debian'
        }
    }

    Context 'when no distribution is chosen' {
        It 'keeps the distribution chosen in a previous install' {
            Install-WinPlaybookShim -Distribution 'Debian' | Out-Null

            Install-WinPlaybookShim | Out-Null

            (Get-SavedSetting).WslDistribution | Should-Be 'Debian'
        }

        It 'fails on the first install without creating the shim folder' {
            { Install-WinPlaybookShim } | Should-Throw -ExceptionMessage '*Install-WinPlaybookShim -Distribution*'

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }
    }

    Context 'when the chosen distribution does not exist' {
        It 'fails without creating the shim folder' {
            { Install-WinPlaybookShim -Distribution 'Missing' } | Should-Throw -ExceptionMessage '*distribution Missing does not exist*'

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }
    }

    Context 'when a folder is chosen' {
        It 'creates the shims in a WinPlaybook folder inside it' {
            $chosenFolder = Join-Path $TestDrive 'tools'

            Install-WinPlaybookShim -Distribution 'Ubuntu' -Path $chosenFolder | Out-Null

            Test-Path -LiteralPath (Join-Path $chosenFolder 'WinPlaybook/bin/ansible-playbook.ps1') | Should-BeTrue
        }
    }

    Context 'when the distribution no longer has a command' {
        It 'removes the shim of that command' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null
            Mock Get-AnsibleCommand -ModuleName WinPlaybook { 'ansible' }

            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            Test-Path -LiteralPath (Join-Path $defaultShimFolder 'ansible-playbook.ps1') | Should-BeFalse
        }
    }

    Context 'when the shim folder exists and was not created by WinPlaybook' {
        It 'refuses to install and keeps the files of the folder' {
            New-Item -ItemType Directory -Path $defaultShimFolder -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $defaultShimFolder 'mine.txt') -Value 'mine'

            { Install-WinPlaybookShim -Distribution 'Ubuntu' } | Should-Throw -ExceptionMessage '*not created by WinPlaybook*'

            Test-Path -LiteralPath (Join-Path $defaultShimFolder 'mine.txt') | Should-BeTrue
        }
    }

    Context 'when the shims were installed in another folder' {
        It 'removes the previous shims' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            Install-WinPlaybookShim -Distribution 'Ubuntu' -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))) | Out-Null

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }

        It 'removes the previous folder from the user Path' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            Install-WinPlaybookShim -Distribution 'Ubuntu' -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))) | Out-Null

            Should-Invoke Remove-UserPathEntry -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Folder -eq $defaultShimFolder
            }
        }
    }

    Context 'when the commands of the distribution cannot be listed' {
        BeforeAll {
            Mock Get-AnsibleCommand -ModuleName WinPlaybook { throw 'wsl is not running' }
        }

        It 'fails without creating the shim folder' {
            { Install-WinPlaybookShim -Distribution 'Ubuntu' } | Should-Throw -ExceptionMessage '*wsl is not running*'

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }
    }

    Context 'when called with -WhatIf' {
        It 'creates no shim folder' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -WhatIf

            Test-Path -LiteralPath $defaultShimFolder | Should-BeFalse
        }

        It 'leaves the user Path unchanged' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -WhatIf

            Should-NotInvoke Add-UserPathEntry -ModuleName WinPlaybook
        }
    }

    Context 'when a PowerShell edition is chosen' {
        It 'saves that edition for the executable shims' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -PowerShell 'Desktop' | Out-Null

            (Get-SavedSetting).ShimPowerShellPath | Should-Be $desktopPowerShellPath
        }
    }

    Context 'when no PowerShell edition is chosen' {
        It 'uses the PowerShell that is running on the first install' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            (Get-SavedSetting).ShimPowerShellPath | Should-Be $currentPowerShellPath
        }

        It 'keeps the PowerShell chosen in a previous install' {
            Install-WinPlaybookShim -Distribution 'Ubuntu' -PowerShell 'Desktop' | Out-Null

            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            (Get-SavedSetting).ShimPowerShellPath | Should-Be $desktopPowerShellPath
        }

        It 'uses the PowerShell that is running when the saved one no longer exists' {
            New-Item -ItemType Directory -Path $configFolder | Out-Null
            Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Value '{ "ShimPowerShellPath": "C:\\Missing\\pwsh.exe" }'

            Install-WinPlaybookShim -Distribution 'Ubuntu' | Out-Null

            (Get-SavedSetting).ShimPowerShellPath | Should-Be $currentPowerShellPath
        }
    }
}
