BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
    Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
    Mock Write-Log -ModuleName WinPlaybook { }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Write-ProgressoDoAdministrador' {
    AfterEach {
        Remove-Item -LiteralPath 'Env:WINPLAYBOOK_PROGRESS_FILE' -ErrorAction SilentlyContinue
    }

    It 'acrescenta o evento ao arquivo de WINPLAYBOOK_PROGRESS_FILE' {
        $env:WINPLAYBOOK_PROGRESS_FILE = Join-Path $TestDrive 'progresso.txt'

        InModuleScope WinPlaybook { Write-ProgressoDoAdministrador -Id 'localhost.openssh'; Write-ProgressoDoAdministrador -Id 'localhost.openssh' -Fim; Write-ProgressoDoAdministrador -Id 'localhost.remover' -Remocao }

        Get-Content -LiteralPath $env:WINPLAYBOOK_PROGRESS_FILE -Encoding UTF8 | Should-BeCollection @('inicio localhost.openssh', 'fim localhost.openssh', 'remocao localhost.remover')
    }

    It 'atualiza o plano em andamento sem a variável' {
        Mock Set-EventoDoPlano -ModuleName WinPlaybook { }

        InModuleScope WinPlaybook {
            $plano = New-Plano -Itens @{ Id = 'localhost.openssh'; Texto = 'Baixar o OpenSSH' }
            Write-ProgressoDoAdministrador -Id 'localhost.openssh' -Fim
            Close-Plano -Plano $plano
        }

        Should-Invoke Set-EventoDoPlano -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Evento -eq 'fim' -and $Id -eq 'localhost.openssh' }
    }
}
