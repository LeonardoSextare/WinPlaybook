BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Invoke-EtapaOpcional' {
    It 'devolve $true quando a ação dá certo' {
        $deuCerto = InModuleScope WinPlaybook { Invoke-EtapaOpcional -Texto 'Ligando' -Resultado 'Ligado' -ComandoParaTentarDeNovo 'Enable-X' -Pagina 'pagina' -Acao { } } 6> $null

        $deuCerto | Should-BeTrue
    }

    It 'mostra a causa, o comando para tentar de novo e a ajuda, sem interromper, quando a ação falha' {
        $saida = InModuleScope WinPlaybook { Invoke-EtapaOpcional -Texto 'Ligando' -Resultado 'Ligado' -ComandoParaTentarDeNovo 'Enable-X' -Pagina 'pagina' -Acao { throw 'sem permissão' } } 6>&1 | Out-String

        $saida | Should-BeLikeString '*`[x`]* Ligando*sem permissão*Para tentar de novo: Enable-X*Ajuda: https://leonardosextare.github.io/WinPlaybook/pt-br/pagina/*False*'
    }
}
