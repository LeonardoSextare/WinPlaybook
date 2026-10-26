BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PowerShellPath' {
    Context 'when no edition is chosen' {
        It 'returns the PowerShell that is running' {
            $result = InModuleScope WinPlaybook { Get-PowerShellPath }

            $result | Should-Be (Get-Process -Id $PID).Path
        }
    }

    Context 'when the Desktop edition is chosen' {
        It 'returns Windows PowerShell' {
            $expected = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

            $result = InModuleScope WinPlaybook { Get-PowerShellPath -Edition 'Desktop' }

            $result | Should-Be $expected
        }
    }

    Context 'when the Core edition is chosen and PowerShell 7 is installed' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'pwsh' } {
                [pscustomobject]@{ Source = 'C:\PowerShell\7\pwsh.exe' }
            }
        }

        It 'returns PowerShell 7' {
            $result = InModuleScope WinPlaybook { Get-PowerShellPath -Edition 'Core' }

            $result | Should-Be 'C:\PowerShell\7\pwsh.exe'
        }
    }

    Context 'when the Core edition is chosen and PowerShell 7 is not installed' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'pwsh' } { }
        }

        It 'explains that PowerShell 7 is missing' {
            { InModuleScope WinPlaybook { Get-PowerShellPath -Edition 'Core' } } | Should-Throw -ExceptionMessage '*PowerShell 7*'
        }
    }
}
