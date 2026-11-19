BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Write-LinhaDaEtapa' {
    It 'escreve a marca e o texto' {
        $saida = InModuleScope WinPlaybook { Write-LinhaDaEtapa -Marca '[+]' -Cor 'Green' -Texto 'Pronto' } 6>&1 | Out-String

        $saida | Should-BeLikeString '*`[+`]* Pronto*'
    }
}
