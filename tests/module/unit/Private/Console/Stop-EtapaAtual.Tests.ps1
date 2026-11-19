BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Stop-EtapaAtual' {
    It 'esquece a etapa em andamento' {
        $temEtapa = InModuleScope WinPlaybook {
            $null = Start-Etapa -Texto 'Instalando o Ansible'
            Stop-EtapaAtual
            $null -ne (Get-Variable -Name 'EtapaAtual' -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
        }

        $temEtapa | Should-BeFalse
    }
}
