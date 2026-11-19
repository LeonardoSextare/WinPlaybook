BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Plano' {
    It 'fora de um terminal, mostra cada etapa quando ela termina, com o título antes da primeira etapa dele' {
        $saida = InModuleScope WinPlaybook {
            $plano = New-Plano -Itens @(
                @{ Id = 'ansible'; Texto = 'Instalar o Ansible' }
                @{ Id = 'localhost'; Texto = 'Ligar o localhost_windows'; Titulo = $true }
                @{ Id = 'localhost.chave'; Texto = 'Criar a chave'; Recuo = 1 }
                @{ Id = 'vscode'; Texto = 'Corrigir o VS Code' }
            )
            Start-ItemDoPlano -Plano $plano -Id 'ansible'
            Start-ItemDoPlano -Plano $plano -Id 'localhost.chave'
            Complete-ItemDoPlano -Plano $plano -Id 'localhost.chave' -Remocao
            Start-ItemDoPlano -Plano $plano -Id 'vscode'
            Close-Plano -Plano $plano
        } 6>&1 | Out-String

        $saida | Should-BeLikeString '*`[*+*`] Instalar o Ansible*Ligar o localhost_windows*`[*-*`] Criar a chave*`[*x*`] Corrigir o VS Code*'
    }

    It 'registra no log o tempo de cada etapa' {
        InModuleScope WinPlaybook {
            $plano = New-Plano -Itens @{ Id = 'ansible'; Texto = 'Instalar o Ansible' }
            Start-ItemDoPlano -Plano $plano -Id 'ansible'
            Complete-ItemDoPlano -Plano $plano -Id 'ansible'
            Close-Plano -Plano $plano
        } 6> $null

        Should-Invoke Write-Log -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Mensagem -like 'Instalar o Ansible terminou em * ms' }
    }

    It 'faz um plano de dentro de outro usar as etapas do de fora, sem fechá-lo' {
        $resultado = InModuleScope WinPlaybook {
            $deFora = New-Plano -Itens @{ Id = 'localhost.chave'; Texto = 'Criar a chave' }
            $deDentro = New-Plano -Itens @{ Id = 'localhost.chave'; Texto = 'Criar a chave' }
            Start-ItemDoPlano -Plano $deDentro -Id 'localhost.chave'
            Close-Plano -Plano $deDentro
            $continuaAberto = $null -ne $script:Plano
            $emAndamento = $deFora.EmAndamento
            Close-Plano -Plano $deFora
            @{ Aninhado = $deDentro.Aninhado; ContinuaAberto = $continuaAberto; EmAndamento = $emAndamento }
        } 6> $null

        $resultado.Aninhado | Should-BeTrue
        $resultado.ContinuaAberto | Should-BeTrue
        $resultado.EmAndamento | Should-Be 'localhost.chave'
    }

    It 'ignora uma etapa que não está no plano' {
        $saida = InModuleScope WinPlaybook {
            $plano = New-Plano -Itens @{ Id = 'ansible'; Texto = 'Instalar o Ansible' }
            Start-ItemDoPlano -Plano $plano -Id 'outra'
            Complete-ItemDoPlano -Plano $plano -Id 'outra'
            Close-Plano -Plano $plano
        } 6>&1 | Out-String

        $saida.Trim() | Should-Be ''
    }
}
