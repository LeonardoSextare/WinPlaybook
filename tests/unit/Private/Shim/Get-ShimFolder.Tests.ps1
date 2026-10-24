BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ShimFolder' {
    It 'returns the bin folder of WinPlaybook in the local application data' {
        $expected = Join-Path (Join-Path $env:LOCALAPPDATA 'WinPlaybook') 'bin'

        $result = InModuleScope WinPlaybook { Get-ShimFolder }

        $result | Should-Be $expected
    }
}
