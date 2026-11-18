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
            'ansible-playbook', 'yamllint', 'ansible', 'ansible-lint', 'ansible', ''
        }
        Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $false }
    }

    Context 'quando a distribuição lista os comandos do ambiente do Ansible' {
        It 'devolve os comandos em ordem e sem repetição, inclusive os dos pacotes extras' {
            $resultado = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' }

            $resultado | Should-BeCollection @('ansible', 'ansible-lint', 'ansible-playbook', 'yamllint')
        }

        It 'lista os comandos de ~/.local/bin ligados ao ambiente do Ansible no uv' {
            $null = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                ($args[0..4] -join ' ') -eq '--distribution Ubuntu --exec sh -c' -and $args[5].Contains('"$HOME"/.local/bin/*') -and $args[5].Contains('"$HOME"/.local/share/uv/tools/ansible/*')
            }
        }
    }

    Context 'quando o PowerShell passa argumentos a programas na forma legada' {
        BeforeAll {
            Mock Test-PassagemDeArgumentosLegada -ModuleName WinPlaybook { $true }
        }

        It 'escapa as aspas do script' {
            $null = InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' }

            Should-Invoke wsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $args[5].Contains('\"$comando\"')
            }
        }
    }

    Context 'quando o wsl não consegue listar os comandos' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook { $global:LASTEXITCODE = -1 }
        }

        It 'informa a distribuição que não conseguiu executar' {
            { InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' } } | Should-Throw -ExceptionMessage '*listar os comandos da distribuição WSL Ubuntu*'
        }
    }

    Context 'quando a distribuição não tem comandos do Ansible' {
        BeforeAll {
            Mock wsl -ModuleName WinPlaybook {
                $global:LASTEXITCODE = 0
                'yamllint'
            }
        }

        It 'explica que falta o Ansible na distribuição' {
            { InModuleScope WinPlaybook { Get-ComandoDoAnsible -Distribuicao 'Ubuntu' } } | Should-Throw -ExceptionMessage '*Ubuntu não tem comandos do Ansible*Install-WinPlaybook*'
        }
    }
}
