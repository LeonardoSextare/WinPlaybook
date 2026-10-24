BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-WinPlaybook' {
    BeforeAll {
        Mock Invoke-AnsibleContainer -ModuleName WinPlaybook { }
    }

    It 'runs the first argument as the command with the other arguments' {
        Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml --check

        Should-Invoke Invoke-AnsibleContainer -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'ansible-playbook' -and ($Arguments -join ' ') -eq '-i inventory.yml site.yml --check'
        }
    }

    It 'passes arguments with quotes and spaces unchanged' {
        Invoke-WinPlaybook ansible-playbook -e '{"name": "a b"}' site.yml

        Should-Invoke Invoke-AnsibleContainer -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Arguments[1] -eq '{"name": "a b"}'
        }
    }

    It 'runs a command without arguments' {
        Invoke-WinPlaybook ansible

        Should-Invoke Invoke-AnsibleContainer -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'ansible' -and $Arguments.Count -eq 0
        }
    }

    It 'rejects a call without a command' {
        { Invoke-WinPlaybook } | Should-Throw -ExceptionMessage '*command to run*'
    }
}
