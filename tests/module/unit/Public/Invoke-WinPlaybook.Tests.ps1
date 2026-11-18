BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-WinPlaybook' {
    BeforeAll {
        Mock Invoke-ComandoNoWsl -ModuleName WinPlaybook { }
    }

    It 'confere se existe uma versão nova, com a versão do módulo carregado' {
        Mock Show-AvisoDeVersaoNova -ModuleName WinPlaybook { }

        Invoke-WinPlaybook ansible --version

        Should-Invoke Show-AvisoDeVersaoNova -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $VersaoAtual -eq (Get-Module WinPlaybook).Version
        }
    }

    It 'executa o primeiro argumento como o comando, com os outros argumentos' {
        Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml --check

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Comando -eq 'ansible-playbook' -and ($Argumentos -join ' ') -eq '-i inventory.yml site.yml --check'
        }
    }

    It 'passa argumentos com aspas e espaços sem mudança' {
        Invoke-WinPlaybook ansible-playbook -e '{"name": "a b"}' site.yml

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Argumentos[1] -eq '{"name": "a b"}'
        }
    }

    It 'executa um comando sem argumentos' {
        Invoke-WinPlaybook ansible

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Comando -eq 'ansible' -and $Argumentos.Count -eq 0
        }
    }

    It 'repassa o pipeline para a entrada do comando' {
        'linha 1', 'linha 2' | Invoke-WinPlaybook ansible-playbook /dev/stdin

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            ($Entrada -join '|') -eq 'linha 1|linha 2'
        }
    }

    It 'executa o comando sem entrada quando não há pipeline' {
        Invoke-WinPlaybook ansible-playbook site.yml

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Entrada.Count -eq 0
        }
    }

    It 'recusa uma chamada sem comando' {
        { Invoke-WinPlaybook } | Should-Throw -ExceptionMessage 'Informe o comando*'
    }
}
