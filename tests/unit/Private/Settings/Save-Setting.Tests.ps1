BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Save-Setting' {
    BeforeAll {
        $configFolder = Join-Path $TestDrive 'config'
        Mock Get-ConfigFolder -ModuleName WinPlaybook { $configFolder }

        InModuleScope WinPlaybook {
            Save-Setting -Settings @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = 'C:\PowerShell\pwsh.exe' }
        }
    }

    It 'saves the settings as JSON in the config folder' {
        $saved = Get-Content -LiteralPath (Join-Path $configFolder 'settings.json') -Raw | ConvertFrom-Json

        $saved.ShimFolder | Should-Be 'C:\Tools\WinPlaybook\bin'
    }

    It 'saves settings that Get-Setting reads back' {
        $result = InModuleScope WinPlaybook { Get-Setting }

        $result.ShimPowerShellPath | Should-Be 'C:\PowerShell\pwsh.exe'
    }
}
