BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-RaizDeMontagemDoWsl' {
    Context 'quando a distribuição traduz a unidade C: para <CaminhoDaUnidade>' -ForEach @(
        @{ CaminhoDaUnidade = '/mnt/c/'; Esperado = '/mnt/' }
        @{ CaminhoDaUnidade = '/c/'; Esperado = '/' }
        @{ CaminhoDaUnidade = '/windows/drives/c/'; Esperado = '/windows/drives/' }
    ) {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                $CaminhoDaUnidade
            }
        }

        It 'devolve <Esperado>' {
            $resultado = InModuleScope WinPlaybook { Get-RaizDeMontagemDoWsl -Distribuicao 'Ubuntu' }

            $resultado | Should-Be $Esperado
        }
    }

    Context 'quando a distribuição traduz a unidade' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                '/mnt/c/'
            }
        }

        It 'pergunta ao wslpath dessa distribuição' {
            $null = InModuleScope WinPlaybook { Get-RaizDeMontagemDoWsl -Distribuicao 'Ubuntu' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args -join ' ') -eq '--distribution Ubuntu --exec wslpath -a C:\'
            }
        }
    }

    Context 'quando o wsl falha' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = -1
                '/mnt/c/'
            }
        }

        It 'informa a distribuição' {
            { InModuleScope WinPlaybook { Get-RaizDeMontagemDoWsl -Distribuicao 'Ubuntu' } } | Should-Throw -ExceptionMessage '*distribuição WSL Ubuntu monta as unidades do Windows*'
        }
    }

    Context 'quando o wslpath devolve algo que não é a pasta de uma unidade' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'C:\'
            }
        }

        It 'informa a distribuição' {
            { InModuleScope WinPlaybook { Get-RaizDeMontagemDoWsl -Distribuicao 'Ubuntu' } } | Should-Throw -ExceptionMessage '*distribuição WSL Ubuntu monta as unidades do Windows*'
        }
    }
}
