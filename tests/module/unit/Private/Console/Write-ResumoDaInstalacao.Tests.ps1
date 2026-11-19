BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Write-ResumoDaInstalacao' {
    It 'mostra o próximo passo e os primeiros passos' {
        $saida = InModuleScope WinPlaybook { Write-ResumoDaInstalacao } 6>&1 | Out-String

        $saida | Should-BeLikeString '*WinPlaybook instalado.*ansible --version*first-playbook*'
        $saida | Should-NotBeLikeString '*allowedUNCHosts*'
    }

    It 'mostra a configuração do VS Code quando a extensão foi corrigida' {
        $saida = InModuleScope WinPlaybook { Write-ResumoDaInstalacao -CorrigiuOVSCode } 6>&1 | Out-String

        $saida | Should-BeLikeString '*security.allowedUNCHosts*'
    }
}
