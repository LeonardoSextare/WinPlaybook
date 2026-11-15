BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoModeloDeShim' {
    Context 'quando o shim está empacotado com o módulo' {
        BeforeAll {
            Mock Test-Path -ModuleName WinPlaybook { $true }
        }

        It 'devolve o shim da pasta bin do módulo' {
            $esperado = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/bin/shim.exe'))

            $resultado = InModuleScope WinPlaybook { Get-CaminhoDoModeloDeShim }

            $resultado | Should-Be $esperado
        }
    }

    Context 'quando o shim não está empacotado' {
        BeforeAll {
            Mock Test-Path -ModuleName WinPlaybook { $false }
        }

        It 'explica como obter o shim' {
            { InModuleScope WinPlaybook { Get-CaminhoDoModeloDeShim } } | Should-Throw -ExceptionMessage '*Save-Shim.ps1*'
        }
    }
}
