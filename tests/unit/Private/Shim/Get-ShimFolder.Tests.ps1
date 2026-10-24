BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ShimFolder' {
    Context 'when the shims are installed' {
        BeforeAll {
            Mock Get-Setting -ModuleName WinPlaybook { @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = $null } }
        }

        It 'returns the folder saved in the settings' {
            $result = InModuleScope WinPlaybook { Get-ShimFolder }

            $result | Should-Be 'C:\Tools\WinPlaybook\bin'
        }
    }

    Context 'when the shims are not installed' {
        BeforeAll {
            Mock Get-Setting -ModuleName WinPlaybook { @{ ShimFolder = $null; ShimPowerShellPath = $null } }
            Mock Get-ConfigFolder -ModuleName WinPlaybook { 'C:\Users\someone\AppData\Local\WinPlaybook' }
        }

        It 'returns the bin folder inside the config folder' {
            $result = InModuleScope WinPlaybook { Get-ShimFolder }

            $result | Should-Be 'C:\Users\someone\AppData\Local\WinPlaybook\bin'
        }
    }
}
