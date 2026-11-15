BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-Configuracao' {
    Context 'quando a pasta de configuração só tem a configuração' {
        BeforeAll {
            $pastaDeConfiguracao = Join-Path $TestDrive 'so-configuracao'
            $null = New-Item -ItemType Directory -Path $pastaDeConfiguracao
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{}'
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        }

        It 'apaga a pasta de configuração' {
            InModuleScope WinPlaybook { Remove-Configuracao }

            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeFalse
        }
    }

    Context 'quando a pasta de configuração tem outros arquivos' {
        BeforeAll {
            $pastaDeConfiguracao = Join-Path $TestDrive 'outros-arquivos'
            $null = New-Item -ItemType Directory -Path (Join-Path $pastaDeConfiguracao 'bin') -Force
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{}'
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }

            InModuleScope WinPlaybook { Remove-Configuracao }
        }

        It 'apaga o arquivo de configuração' {
            Test-Path -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') | Should-BeFalse
        }

        It 'mantém a pasta de configuração' {
            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeTrue
        }
    }

    Context 'quando não há configuração' {
        BeforeAll {
            Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { Join-Path $TestDrive 'inexistente' }
        }

        It 'não faz nada' {
            $resultado = InModuleScope WinPlaybook { Remove-Configuracao }

            $resultado | Should-BeNull
        }
    }
}
