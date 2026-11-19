BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Set-TextoDaEtapa' {
    It 'troca o texto da etapa em andamento, e o resultado sem texto próprio usa o texto novo' {
        $saida = InModuleScope WinPlaybook {
            $etapa = Start-Etapa -Texto 'Ligando o localhost_windows'
            Set-TextoDaEtapa -Texto 'Instalando o OpenSSH Server'
            $etapa.Estado.Texto
        }

        $saida | Should-Be 'Instalando o OpenSSH Server'
    }

    It 'não faz nada sem uma etapa em andamento' {
        $resultado = InModuleScope WinPlaybook { Stop-EtapaAtual; Set-TextoDaEtapa -Texto 'Qualquer' }

        $resultado | Should-BeNull
    }
}
