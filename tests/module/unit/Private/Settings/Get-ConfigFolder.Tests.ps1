BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ConfigFolder' {
    It 'returns the WinPlaybook folder in the local application data' {
        $expected = Join-Path $env:LOCALAPPDATA 'WinPlaybook'

        $result = InModuleScope WinPlaybook { Get-ConfigFolder }

        $result | Should-Be $expected
    }
}
