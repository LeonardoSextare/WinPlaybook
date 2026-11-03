BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-WslDistribution' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            'Ubuntu', '', ' docker-desktop '
        }
    }

    Context 'when WSL has distributions' {
        It 'returns their names' {
            $result = InModuleScope WinPlaybook { Get-WslDistribution }

            $result | Should-BeCollection @('Ubuntu', 'docker-desktop')
        }

        It 'asks wsl for the names only' {
            InModuleScope WinPlaybook { Get-WslDistribution } | Out-Null

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq '--list --quiet'
            }
        }

    }

    Context 'when the WSL_UTF8 variable is set' {
        BeforeAll {
            $originalUtf8 = $env:WSL_UTF8
            $env:WSL_UTF8 = 'original'
        }

        AfterAll {
            $env:WSL_UTF8 = $originalUtf8
        }

        It 'restores the variable' {
            InModuleScope WinPlaybook { Get-WslDistribution } | Out-Null

            $env:WSL_UTF8 | Should-Be 'original'
        }
    }

    Context 'when WSL has no distributions' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
        }

        It 'explains how to install one' {
            { InModuleScope WinPlaybook { Get-WslDistribution } } | Should-Throw -ExceptionMessage '*no distributions*wsl --install*'
        }
    }

    Context 'when WSL is not installed' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'wsl' } { }
        }

        It 'explains how to install it' {
            { InModuleScope WinPlaybook { Get-WslDistribution } } | Should-Throw -ExceptionMessage 'WSL was not found*wsl --install*'
        }
    }
}
