BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-DistribuicaoDoWsl' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            'Ubuntu', '', ' Debian '
        }
    }

    Context 'quando o WSL tem distribuições' {
        It 'devolve os nomes delas' {
            $resultado = InModuleScope WinPlaybook { Get-DistribuicaoDoWsl }

            $resultado | Should-BeCollection @('Ubuntu', 'Debian')
        }

        It 'pede ao wsl só os nomes' {
            $null = InModuleScope WinPlaybook { Get-DistribuicaoDoWsl }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq '--list --quiet'
            }
        }
    }

    Context 'quando a variável WSL_UTF8 está definida' {
        BeforeAll {
            $utf8Original = $env:WSL_UTF8
            $env:WSL_UTF8 = 'original'
        }

        AfterAll {
            $env:WSL_UTF8 = $utf8Original
        }

        It 'restaura a variável' {
            $null = InModuleScope WinPlaybook { Get-DistribuicaoDoWsl }

            $env:WSL_UTF8 | Should-Be 'original'
        }
    }

    Context 'quando o WSL não tem distribuições' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
        }

        It 'explica como instalar uma' {
            { InModuleScope WinPlaybook { Get-DistribuicaoDoWsl } } | Should-Throw -ExceptionMessage '*não tem distribuições*wsl --install*'
        }
    }

    Context 'quando o WSL não está instalado' {
        BeforeAll {
            Mock Get-Command -ModuleName WinPlaybook -ParameterFilter { $Name -eq 'wsl' } { }
        }

        It 'explica como instalar o WSL' {
            { InModuleScope WinPlaybook { Get-DistribuicaoDoWsl } } | Should-Throw -ExceptionMessage 'O WSL não foi encontrado*wsl --install*'
        }
    }
}
