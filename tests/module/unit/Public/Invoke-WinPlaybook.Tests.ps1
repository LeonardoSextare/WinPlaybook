BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-WinPlaybook' {
    BeforeAll {
        Mock Invoke-ComandoNoWsl -ModuleName WinPlaybook { }
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

    It 'recusa uma chamada sem comando' {
        { Invoke-WinPlaybook } | Should-Throw -ExceptionMessage 'Informe o comando*'
    }
}
