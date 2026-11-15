Describe 'Add-EntradaNoPathDoUsuario' {
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

    Context 'quando a pasta não está na variável do usuário' {
        It 'coloca a pasta no começo' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Tools;C:\Other'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be 'C:\Shims;C:\Tools;C:\Other'
        }

        It 'mantém as entradas que usam variáveis de ambiente' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor '%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be 'C:\Shims;%USERPROFILE%\bin'
        }

        It 'grava a variável como texto expansível' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor '%USERPROFILE%\bin'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Tipo | Should-Be 'ExpandString'
        }
    }

    Context 'quando a variável do usuário não existe' {
        It 'cria a variável com a pasta' {
            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be 'C:\Shims'
        }
    }

    Context 'quando a pasta já está na variável do usuário' {
        It 'deixa a variável como está quando a entrada é <Entrada>' -ForEach @(
            @{ Entrada = 'c:\shims\'; Pasta = 'C:\Shims' }
            @{ Entrada = '%TEMP%\winplaybook-shims'; Pasta = Join-Path $env:TEMP 'winplaybook-shims' }
        ) {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor "C:\Tools;$Entrada"

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel; Pasta = $Pasta } {
                Add-EntradaNoPathDoUsuario -Pasta $Pasta -NomeDaVariavel $Nome
            }

            (Get-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel).Valor | Should-Be "C:\Tools;$Entrada"
        }
    }

    Context 'quando a pasta não está na sessão atual' {
        It 'coloca a pasta no começo da variável da sessão' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Shims'
            Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\Windows'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-Item -LiteralPath "Env:$nomeDaVariavel").Value | Should-Be 'C:\Shims;C:\Windows'
        }
    }

    Context 'quando a pasta já está na sessão atual' {
        It 'deixa a variável da sessão como está' {
            Set-VariavelDeUsuarioDeTeste -Nome $nomeDaVariavel -Valor 'C:\Shims'
            Set-Item -LiteralPath "Env:$nomeDaVariavel" -Value 'C:\Windows;C:\Shims'

            InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDaVariavel } {
                Add-EntradaNoPathDoUsuario -Pasta 'C:\Shims' -NomeDaVariavel $Nome
            }

            (Get-Item -LiteralPath "Env:$nomeDaVariavel").Value | Should-Be 'C:\Windows;C:\Shims'
        }
    }
}
