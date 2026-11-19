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

    It 'acrescenta o texto ao arquivo de WINPLAYBOOK_PROGRESS_FILE' {
        $env:WINPLAYBOOK_PROGRESS_FILE = Join-Path $TestDrive 'progresso.txt'

        InModuleScope WinPlaybook { Write-ProgressoDoAdministrador -Texto 'Instalando o OpenSSH Server'; Write-ProgressoDoAdministrador -Texto 'Criando o serviço' }

        Get-Content -LiteralPath $env:WINPLAYBOOK_PROGRESS_FILE -Encoding UTF8 | Should-BeCollection @('Instalando o OpenSSH Server', 'Criando o serviço')
    }

    It 'troca o texto da etapa em andamento sem a variável' {
        Mock Set-TextoDaEtapa -ModuleName WinPlaybook { }

        InModuleScope WinPlaybook { Write-ProgressoDoAdministrador -Texto 'Instalando o OpenSSH Server' }

        Should-Invoke Set-TextoDaEtapa -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Texto -eq 'Instalando o OpenSSH Server' }
    }
}
