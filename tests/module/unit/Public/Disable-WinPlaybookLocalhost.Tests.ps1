BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Disable-WinPlaybookLocalhost' {
    BeforeEach {
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'WinPlaybook'; LocalhostWindowsPort = 47022; LocalhostWindowsUser = 'eu'; OpenSshServerInstalledByWinPlaybook = $true } }
        Mock Save-Configuracao -ModuleName WinPlaybook { }
        Mock Remove-SshdDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Invoke-ComoAdministrador -ModuleName WinPlaybook { }
        Mock Test-Administrador -ModuleName WinPlaybook { $true }
    }

    It 'apaga o serviço SSH e o OpenSSH do WinPlaybook' {
        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Remove-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'esquece a porta e o usuário' {
        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Save-Configuracao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            -not $Configuracao['LocalhostWindowsPort'] -and -not $Configuracao['LocalhostWindowsUser']
        }
    }

    It 'pede ao Windows um PowerShell de administrador quando não é elevado' {
        Mock Test-Administrador -ModuleName WinPlaybook { $false }

        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Invoke-ComoAdministrador -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Comando -eq 'Disable-WinPlaybookLocalhost -Confirm:$false' }
        Should-Invoke Remove-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'não faz nada com o localhost_windows desligado' {
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'WinPlaybook' } }

        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Invoke-ComoAdministrador -ModuleName WinPlaybook -Times 0 -Exactly
        Should-Invoke Remove-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
    }
}
