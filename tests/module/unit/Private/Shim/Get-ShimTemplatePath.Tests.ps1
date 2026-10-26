BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-ShimTemplatePath' {
    Context 'when the shim is packaged with the module' {
        BeforeAll {
            Mock Test-Path -ModuleName WinPlaybook { $true }
        }

        It 'returns the shim in the bin folder of the module' {
            $expected = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/bin/shim.exe'))

            $result = InModuleScope WinPlaybook { Get-ShimTemplatePath }

            $result | Should-Be $expected
        }
    }

    Context 'when the shim is missing' {
        BeforeAll {
            Mock Test-Path -ModuleName WinPlaybook { $false }
        }

        It 'explains how to get it' {
            { InModuleScope WinPlaybook { Get-ShimTemplatePath } } | Should-Throw -ExceptionMessage '*Save-Shim.ps1*'
        }
    }
}
