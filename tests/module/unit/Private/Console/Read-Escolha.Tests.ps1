BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Read-Escolha' {
    It 'devolve <Esperado> com a resposta "<Resposta>"' -ForEach @(
        @{ Resposta = ''; Esperado = $true }
        @{ Resposta = 's'; Esperado = $true }
        @{ Resposta = 'N'; Esperado = $false }
    ) {
        Mock Read-Host -ModuleName WinPlaybook -MockWith ([scriptblock]::Create("'$Resposta'"))

        $escolha = InModuleScope WinPlaybook { Read-Escolha -Pergunta 'Ativar?' -Explicacao 'Faz algo.' -Link 'https://exemplo' -AjudaDoSim 'liga' -AjudaDoNao 'não liga' } 6> $null

        $escolha | Should-Be $Esperado
    }

    It 'mostra a pergunta como recomendada, o link e o prompt no formato do PowerShell, em português' {
        Mock Read-Host -ModuleName WinPlaybook { '' }

        $saida = InModuleScope WinPlaybook { $null = Read-Escolha -Pergunta 'Ativar?' -Explicacao 'Faz algo.' -Link 'https://exemplo' -AjudaDoSim 'liga' -AjudaDoNao 'não liga' } 6>&1 | Out-String

        $saida | Should-BeLikeString '*Ativar?*(recomendado)*Faz algo.*Saiba mais: https://exemplo*`[S`] Sim*`[N`] Não  `[?`] Ajuda (o padrão é "S")*'
    }

    It 'mostra a ajuda das opções com ? e pergunta de novo' {
        $script:respostas = [Collections.Generic.Queue[string]]::new([string[]] @('?', 'n'))
        Mock Read-Host -ModuleName WinPlaybook { $script:respostas.Dequeue() }

        $saida = InModuleScope WinPlaybook { $null = Read-Escolha -Pergunta 'Ativar?' -Explicacao 'Faz algo.' -Link 'https://exemplo' -AjudaDoSim 'liga' -AjudaDoNao 'não liga' } 6>&1 | Out-String

        $saida | Should-BeLikeString '*S - liga*N - não liga*'
        Should-Invoke Read-Host -ModuleName WinPlaybook -Times 2 -Exactly
    }
}
