BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CompletacaoDoAnsible' {
    BeforeAll {
        Mock Invoke-ComandoNoWsl -ModuleName WinPlaybook { "--check`n--diff`n`n" }
    }

    It 'devolve uma opção por item, sem linhas vazias' {
        $opcoes = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --' }

        $opcoes | Should-BeCollection @('--check', '--diff')
    }

    It 'roda o argcomplete na distribuição com o comando e a linha até o cursor' {
        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --' }

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Comando -eq '/usr/bin/python3' -and $Argumentos[1].Contains('_ARGCOMPLETE="1"') -and $Argumentos[2] -eq 'ansible-playbook' -and $Argumentos[3] -eq 'ansible-playbook --'
        }
    }
}
