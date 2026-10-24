BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-Setting' {
    Context 'when there is no settings file' {
        BeforeAll {
            Mock Get-ConfigFolder -ModuleName WinPlaybook { Join-Path $TestDrive 'no-settings' }
        }

        It 'returns no shim folder' {
            $result = InModuleScope WinPlaybook { Get-Setting }

            $result.ShimFolder | Should-BeNull
        }

        It 'returns no shim PowerShell path' {
            $result = InModuleScope WinPlaybook { Get-Setting }

            $result.ShimPowerShellPath | Should-BeNull
        }
    }

    Context 'when the settings file exists' {
        BeforeAll {
            $configFolder = Join-Path $TestDrive 'with-settings'
            New-Item -ItemType Directory -Path $configFolder | Out-Null
            Set-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Value '{ "ShimFolder": "C:\\Tools\\WinPlaybook\\bin", "ShimPowerShellPath": "C:\\PowerShell\\pwsh.exe" }'
            Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }
        }

        It 'returns the saved shim folder' {
            $result = InModuleScope WinPlaybook { Get-Setting }

            $result.ShimFolder | Should-Be 'C:\Tools\WinPlaybook\bin'
        }

        It 'returns the saved shim PowerShell path' {
            $result = InModuleScope WinPlaybook { Get-Setting }

            $result.ShimPowerShellPath | Should-Be 'C:\PowerShell\pwsh.exe'
        }
    }
}
