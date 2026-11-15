BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-Configuracao' {
    Context 'quando não há arquivo de configuração' {
        BeforeAll {
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { Join-Path $TestDrive 'sem-configuracao' }
        }

        It 'não devolve pasta dos shims' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.ShimFolder | Should-BeNull
        }

        It 'não devolve PowerShell dos shims' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.ShimPowerShellPath | Should-BeNull
        }

        It 'não devolve distribuição WSL' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.WslDistribution | Should-BeNull
        }

        It 'não devolve raiz de montagem do WSL' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.WslMountRoot | Should-BeNull
        }
    }

    Context 'quando o arquivo de configuração existe' {
        BeforeAll {
            $pastaDeConfiguracao = Join-Path $TestDrive 'com-configuracao'
            $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{ "ShimFolder": "C:\\Tools\\WinPlaybook\\bin", "ShimPowerShellPath": "C:\\PowerShell\\pwsh.exe", "WslDistribution": "Ubuntu" }'
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        }

        It 'devolve a pasta dos shims salva' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.ShimFolder | Should-Be 'C:\Tools\WinPlaybook\bin'
        }

        It 'devolve o PowerShell dos shims salvo' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.ShimPowerShellPath | Should-Be 'C:\PowerShell\pwsh.exe'
        }

        It 'devolve a distribuição WSL salva' {
            $resultado = InModuleScope WinPlaybook { Get-Configuracao }

            $resultado.WslDistribution | Should-Be 'Ubuntu'
        }
    }
}
