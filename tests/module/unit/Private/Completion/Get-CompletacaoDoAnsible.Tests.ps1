BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Get-CompletacaoDoAnsible' {
    BeforeEach {
        Mock Invoke-ComandoNoWsl -ModuleName WinPlaybook { "--check`n--diff`n`n" }
        InModuleScope WinPlaybook { Remove-Variable -Name 'opcoesDoAutocomplete' -Scope Script -ErrorAction SilentlyContinue }
    }

    It 'devolve uma opção por item, sem linhas vazias' {
        $opcoes = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --' }

        $opcoes | Should-BeCollection @('--check', '--diff')
    }

    It 'roda o argcomplete na distribuição com o comando e a linha até o começo da opção' {
        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook site.yml --' }

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            $Comando -eq '/usr/bin/python3' -and $Argumentos[1].Contains('_ARGCOMPLETE="1"') -and $Argumentos[2] -eq 'ansible-playbook' -and $Argumentos[3] -eq 'ansible-playbook site.yml -'
        }
    }

    It 'filtra as opções pelo que já foi digitado' {
        $opcoes = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --ch' }

        $opcoes | Should-BeCollection @('--check')
    }

    It 'reaproveita as opções do mesmo contexto, sem chamar a distribuição de novo' {
        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --ch' }

        $opcoes = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook --d' }

        $opcoes | Should-BeCollection @('--diff')
        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'pergunta à distribuição de novo quando as palavras anteriores mudam' {
        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-galaxy' -Linha 'ansible-galaxy collection --' }

        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-galaxy' -Linha 'ansible-galaxy role --' }

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 2 -Exactly
    }

    It 'pergunta sempre à distribuição quando a palavra não é uma opção, como um arquivo' {
        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook si' }

        $null = InModuleScope WinPlaybook { Get-CompletacaoDoAnsible -Comando 'ansible-playbook' -Linha 'ansible-playbook si' }

        Should-Invoke Invoke-ComandoNoWsl -ModuleName WinPlaybook -Times 2 -Exactly -ParameterFilter { $Argumentos[3] -eq 'ansible-playbook si' }
    }
}
