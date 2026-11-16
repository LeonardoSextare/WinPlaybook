BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CaminhoDoPowerShell' {
    Context 'quando nenhuma edição é escolhida' {
        It 'devolve o PowerShell em execução' {
            $resultado = InModuleScope WinPlaybook { Get-CaminhoDoPowerShell }

            $resultado | Should-Be (Get-Process -Id $PID).Path
        }
    }

    Context 'quando a edição Desktop é escolhida' {
        It 'devolve o Windows PowerShell' {
            $esperado = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

            $resultado = InModuleScope WinPlaybook { Get-CaminhoDoPowerShell -Edicao 'Desktop' }

            $resultado | Should-Be $esperado
        }
    }

    Context 'quando a edição Core é escolhida e o PowerShell 7 está instalado' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'pwsh' } {
                [pscustomobject]@{ Source = 'C:\PowerShell\7\pwsh.exe' }
            }
        }

        It 'devolve o PowerShell 7' {
            $resultado = InModuleScope WinPlaybook { Get-CaminhoDoPowerShell -Edicao 'Core' }

            $resultado | Should-Be 'C:\PowerShell\7\pwsh.exe'
        }
    }

    Context 'quando a edição Core é escolhida e o PowerShell 7 não está instalado' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'pwsh' } { }
        }

        It 'explica que falta o PowerShell 7' {
            { InModuleScope WinPlaybook { Get-CaminhoDoPowerShell -Edicao 'Core' } } | Should-Throw -ExceptionMessage '*PowerShell 7*winget install*'
        }
    }
}
