BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Set-EventoDoPlano' {
    BeforeEach {
        Mock Start-ItemDoPlano -ModuleName WinPlaybook { }
        Mock Complete-ItemDoPlano -ModuleName WinPlaybook { }
    }

    It 'começa a etapa com inicio' {
        InModuleScope WinPlaybook { Set-EventoDoPlano -Plano @{} -Evento 'inicio' -Id 'ansible' }

        Should-Invoke Start-ItemDoPlano -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Id -eq 'ansible' }
    }

    It 'termina a etapa com fim e com remocao' {
        InModuleScope WinPlaybook { Set-EventoDoPlano -Plano @{} -Evento 'fim' -Id 'ansible'; Set-EventoDoPlano -Plano @{} -Evento 'remocao' -Id 'servico' }

        Should-Invoke Complete-ItemDoPlano -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Id -eq 'ansible' -and -not $Remocao }
        Should-Invoke Complete-ItemDoPlano -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Id -eq 'servico' -and $Remocao }
    }
}
