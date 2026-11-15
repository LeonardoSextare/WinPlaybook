Describe 'Remove-EntradaDoPathDoUsuario' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
        . (Join-Path $PSScriptRoot '../../../helpers/Ambiente.ps1')
        Clear-VariavelDeTeste
    }

    AfterAll {
        Clear-VariavelDeTeste
        Remove-Module WinPlaybook
    }

    BeforeEach {
        $nomeDaVariavel = New-NomeDeVariavelDeTeste
    }

    AfterEach {
        Remove-VariavelDeTeste -Nome $nomeDaVariavel
    }

    Context 'quando a pasta está na variável do usuário' {
        It 'tira a pasta e mantém as outras entradas' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Tools;c:\shims\;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be 'C:\Tools;%USERPROFILE%\bin'
        }

        It 'mantém a variável como texto expansível' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Shims;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Tipo | Should-Be 'ExpandString'
        }
    }

    Context 'quando a pasta é a única entrada da variável do usuário' {
        It 'apaga a variável' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel | Should-BeNull
        }
    }

    Context 'quando a pasta não está na variável do usuário' {
        It 'deixa a variável como está' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Tools;%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be 'C:\Tools;%USERPROFILE%\bin'
        }
    }

    Context 'quando a pasta está na sessão atual' {
        It 'tira a pasta da variável da sessão' {
            Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\Shims;C:\Windows'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-Item -LiteralPath "Env:$nomeDaVariavel").Value | Should-Be 'C:\Windows'
        }

        It 'apaga a variável da sessão quando a pasta é a única entrada dela' {
            Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Remove-EntradaDoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            Test-Path -LiteralPath "Env:$nomeDaVariavel" | Should-BeFalse
        }
    }
}
