BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Write-FalhaDaEtapa' {
    It 'mostra a causa, o comando para tentar de novo e a página de ajuda' {
        $saida = InModuleScope WinPlaybook { Write-FalhaDaEtapa -Causa 'sem permissão' -Comando 'Enable-WinPlaybookLocalhost' -Pagina 'troubleshooting-localhost-windows' } 6>&1 | Out-String

        $saida | Should-BeLikeString '*sem permissão*Para tentar de novo:*Enable-WinPlaybookLocalhost*Ajuda: https://leonardosextare.github.io/WinPlaybook/pt-br/troubleshooting-localhost-windows/*'
    }
}
