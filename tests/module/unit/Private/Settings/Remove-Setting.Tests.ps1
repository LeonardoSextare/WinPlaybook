BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-Setting' {
    Context 'when the config folder has only the settings' {
        BeforeAll {
            $configFolder = Join-Path $TestDrive 'only-settings'
            New-Item -ItemType Directory -Path $configFolder | Out-Null
            Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Value '{}'
            Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }
        }

        It 'removes the config folder' {
            InModuleScope WinPlaybook { Remove-Setting }

            Test-Path -LiteralPath $configFolder | Should-BeFalse
        }
    }

    Context 'when the config folder has other files' {
        BeforeAll {
            $configFolder = Join-Path $TestDrive 'other-files'
            New-Item -ItemType Directory -Path (Join-Path $configFolder 'bin') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Value '{}'
            Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }

            InModuleScope WinPlaybook { Remove-Setting }
        }

        It 'removes the settings file' {
            Test-Path -LiteralPath (Join-Path $configFolder 'settings.json') | Should-BeFalse
        }

        It 'keeps the config folder' {
            Test-Path -LiteralPath $configFolder | Should-BeTrue
        }
    }

    Context 'when there are no settings' {
        BeforeAll {
            Mock Get-ConfigFolder -ModuleName WinPlaybook { Join-Path $TestDrive 'missing' }
        }

        It 'does nothing' {
            $result = InModuleScope WinPlaybook { Remove-Setting }

            $result | Should-BeNull
        }
    }
}
