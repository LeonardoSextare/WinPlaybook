BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Remove-PastaDosShims' {
    BeforeAll {
        Mock Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook { }
    }

    Context 'quando a pasta WinPlaybook só tem os shims' {
        BeforeAll {
            $pastaDeFerramentas = Join-Path $TestDrive 'ferramentas'
            $pastaDosShims = Join-Path $pastaDeFerramentas 'WinPlaybook/bin'
            $null = New-Item -ItemType Directory -Path $pastaDosShims -Force
            Set-Content -LiteralPath (Join-Path $pastaDosShims 'ansible.ps1') -Value 'shim'

            InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaDosShims } { Remove-PastaDosShims -Pasta $Pasta }
        }

        It 'apaga a pasta dos shims' {
            Test-Path -LiteralPath $pastaDosShims | Should-BeFalse
        }

        It 'apaga a pasta WinPlaybook vazia' {
            Test-Path -LiteralPath (Join-Path $pastaDeFerramentas 'WinPlaybook') | Should-BeFalse
        }

        It 'mantém a pasta escolhida pelo usuário' {
            Test-Path -LiteralPath $pastaDeFerramentas | Should-BeTrue
        }

        It 'tira a pasta dos shims do Path do usuário' {
            Should-Invoke Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaDosShims
            }
        }
    }

    Context 'quando a pasta WinPlaybook tem outros arquivos' {
        BeforeAll {
            $pastaDeConfiguracao = Join-Path $TestDrive 'configuracao'
            $pastaDosShims = Join-Path $pastaDeConfiguracao 'bin'
            $null = New-Item -ItemType Directory -Path $pastaDosShims -Force
            Set-Content -LiteralPath (Join-Path $pastaDeConfiguracao 'settings.json') -Value '{}'

            InModuleScope WinPlaybook -Parameters @{ Pasta = $pastaDosShims } { Remove-PastaDosShims -Pasta $Pasta }
        }

        It 'mantém a pasta WinPlaybook' {
            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeTrue
        }
    }
}
