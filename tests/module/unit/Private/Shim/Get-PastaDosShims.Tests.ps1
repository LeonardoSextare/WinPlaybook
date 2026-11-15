BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-PastaDosShims' {
    Context 'quando os shims estão instalados' {
        BeforeAll {
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ ShimFolder = 'C:\Tools\WinPlaybook\bin'; ShimPowerShellPath = $null } }
        }

        It 'devolve a pasta salva na configuração' {
            $resultado = InModuleScope WinPlaybook { Get-PastaDosShims }

            $resultado | Should-Be 'C:\Tools\WinPlaybook\bin'
        }
    }

    Context 'quando os shims não estão instalados' {
        BeforeAll {
            Mock Get-Configuracao -ModuleName WinPlaybook { @{ ShimFolder = $null; ShimPowerShellPath = $null } }
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { 'C:\Users\alguem\AppData\Local\WinPlaybook' }
        }

        It 'devolve a pasta bin dentro da pasta de configuração' {
            $resultado = InModuleScope WinPlaybook { Get-PastaDosShims }

            $resultado | Should-Be 'C:\Users\alguem\AppData\Local\WinPlaybook\bin'
        }
    }
}
