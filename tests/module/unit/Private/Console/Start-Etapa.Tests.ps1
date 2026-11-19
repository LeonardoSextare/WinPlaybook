BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Start-Etapa' {
    It 'não mostra nada fora de um terminal interativo' {
        $saida = InModuleScope WinPlaybook { $null = Start-Etapa -Texto 'Instalando o Ansible' } 6>&1 | Out-String

        $saida.Trim() | Should-Be ''
    }
}
