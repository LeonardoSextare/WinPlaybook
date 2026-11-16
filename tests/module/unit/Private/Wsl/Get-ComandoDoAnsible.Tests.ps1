BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
    $global:LASTEXITCODE = 0
}

Describe 'Get-ComandoDoAnsible' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook {
            $global:LASTEXITCODE = 0
            'python3', 'ansible-playbook', 'ansible', 'ansible-lint', 'ansible', 'pip'
        }
        Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $false }
    }

    Context 'quando a distribuição lista os comandos dela' {
        It 'devolve os comandos do Ansible em ordem e sem repetição' {
            $resultado = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' }

            $resultado | Should-BeCollection @('ansible', 'ansible-lint', 'ansible-playbook')
        }

        It 'pergunta a um login shell da distribuição' {
            $null = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args[0..4] -join ' ') -eq '--distribution Ubuntu --exec sh -lc'
            }
        }

        It 'passa a raiz de montagem, para o script pular as pastas das unidades do Windows' {
            $null = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $args[-1] -eq '/mnt/'
            }
        }
    }

    Context 'quando o PowerShell passa argumentos a programas na forma legada' {
        BeforeAll {
            Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $true }
        }

        It 'escapa as aspas do script' {
            $null = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $args[5].Contains('\"$0\"')
            }
        }
    }

    Context 'quando o wsl não consegue listar os comandos' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
        }

        It 'informa a distribuição que não conseguiu executar' {
            { InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' } } | Should-Throw -ExceptionMessage '*listar os comandos da distribuição WSL Ubuntu*'
        }
    }

    Context 'quando a distribuição não tem comandos do Ansible' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'python3', 'pip'
            }
        }

        It 'explica que falta o Ansible na distribuição' {
            { InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' } } | Should-Throw -ExceptionMessage '*Ubuntu não tem comandos do Ansible*Install-WinPlaybook*'
        }
    }
}
