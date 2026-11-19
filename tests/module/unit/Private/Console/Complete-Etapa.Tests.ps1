BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Complete-Etapa' {
    It 'mostra [+] com o resultado da etapa' {
        $saida = InModuleScope WinPlaybook { Complete-Etapa -Etapa (Start-Etapa -Texto 'Instalando o Ansible') -Resultado 'Ansible instalado' } 6>&1 | Out-String

        $saida | Should-BeLikeString '*`[+`]*Ansible instalado*'
    }

    It 'mostra [x] com o texto da etapa quando ela falha' {
        $saida = InModuleScope WinPlaybook { Complete-Etapa -Etapa (Start-Etapa -Texto 'Instalando o Ansible') -Falhou } 6>&1 | Out-String

        $saida | Should-BeLikeString '*`[x`]*Instalando o Ansible*'
    }

    It 'registra no log quanto tempo a etapa levou' {
        InModuleScope WinPlaybook { Complete-Etapa -Etapa (Start-Etapa -Texto 'Instalando o Ansible') } 6> $null

        Should-Invoke Write-Log -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Mensagem -like 'Instalando o Ansible terminou em * ms' }
    }
}
