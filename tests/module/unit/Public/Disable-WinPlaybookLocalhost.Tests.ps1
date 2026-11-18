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
        Mock Uninstall-ServidorOpenSsh -ModuleName WinPlaybook { }
        Mock Invoke-ComoAdministrador -ModuleName WinPlaybook { }
        Mock Test-Administrador -ModuleName WinPlaybook { $true }
    }

    It 'apaga o serviço SSH e desinstala o OpenSSH Server que o WinPlaybook instalou' {
        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Remove-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly
        Should-Invoke Uninstall-ServidorOpenSsh -ModuleName WinPlaybook -Times 1 -Exactly
    }

    It 'mantém o OpenSSH Server que já estava instalado' {
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'WinPlaybook'; LocalhostWindowsPort = 47022; OpenSshServerInstalledByWinPlaybook = $false } }

        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Uninstall-ServidorOpenSsh -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'esquece a porta e o usuário' {
        Disable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Save-Configuracao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
            -not $Configuracao['LocalhostWindowsPort'] -and -not $Configuracao['LocalhostWindowsUser'] -and -not $Configuracao['OpenSshServerInstalledByWinPlaybook']
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
