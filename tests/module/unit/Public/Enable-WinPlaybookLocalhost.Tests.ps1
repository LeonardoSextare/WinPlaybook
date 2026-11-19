BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Enable-WinPlaybookLocalhost' {
    BeforeEach {
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = 'WinPlaybook'; LocalhostWindowsDeclined = $true } }
        Mock Save-Configuracao -ModuleName WinPlaybook { }
        Mock New-ChaveDoLocalhostWindows -ModuleName WinPlaybook { 'ssh-ed25519 AAAA winplaybook' }
        Mock Get-UsuarioDoLocalhostWindows -ModuleName WinPlaybook { 'eu' }
        Mock Install-OpenSshDoWinPlaybook -ModuleName WinPlaybook { 'C:\ProgramData\WinPlaybook\openssh' }
        Mock Install-SshdDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Invoke-ComoAdministrador -ModuleName WinPlaybook { }
        Mock Test-Administrador -ModuleName WinPlaybook { $true }
    }

    Context 'quando roda como administrador' {
        BeforeEach {
            Enable-WinPlaybookLocalhost -Confirm:$false
        }

        It 'cria o serviço SSH com a chave da distribuição, o usuário e a porta 47022' {
            Should-Invoke New-ChaveDoLocalhostWindows -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Distribuicao -eq 'WinPlaybook' }
            Should-Invoke Install-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $ChavePublica -eq 'ssh-ed25519 AAAA winplaybook' -and $Usuario -eq 'eu' -and $Porta -eq 47022 -and $PastaDoOpenSsh -eq 'C:\ProgramData\WinPlaybook\openssh'
            }
        }

        It 'guarda a porta e o usuário, e esquece a recusa' {
            Should-Invoke Save-Configuracao -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Configuracao['LocalhostWindowsPort'] -eq 47022 -and $Configuracao['LocalhostWindowsUser'] -eq 'eu' -and -not $Configuracao['LocalhostWindowsDeclined']
            }
        }
    }

    It 'pede ao Windows um PowerShell de administrador quando não é elevado' {
        Mock Test-Administrador -ModuleName WinPlaybook { $false }

        Enable-WinPlaybookLocalhost -Confirm:$false

        Should-Invoke Invoke-ComoAdministrador -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter { $Comando -eq 'Enable-WinPlaybookLocalhost -Confirm:$false' }
        Should-Invoke Install-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
    }

    It 'explica como instalar o WinPlaybook antes' {
        Mock Get-Configuracao -ModuleName WinPlaybook { @{ WslDistribution = $null } }

        { Enable-WinPlaybookLocalhost -Confirm:$false } | Should-Throw -ExceptionMessage '*Install-WinPlaybook*'
    }

    It 'não altera nada com -WhatIf' {
        Enable-WinPlaybookLocalhost -WhatIf

        Should-Invoke Install-SshdDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
        Should-Invoke Invoke-ComoAdministrador -ModuleName WinPlaybook -Times 0 -Exactly
    }
}
