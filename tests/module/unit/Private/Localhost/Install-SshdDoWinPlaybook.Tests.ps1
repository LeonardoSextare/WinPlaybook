BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Install-SshdDoWinPlaybook' {
    BeforeAll {
        $pasta = Join-Path $TestDrive 'sshd'
        Mock Get-PastaDoSshdDoWinPlaybook -ModuleName WinPlaybook { $pasta }
        Mock icacls.exe -ModuleName WinPlaybook { }
        Mock Start-Process -ModuleName WinPlaybook { }
        Mock Get-Service -ModuleName WinPlaybook { $null }
        Mock New-Service -ModuleName WinPlaybook { }
        Mock Start-Service -ModuleName WinPlaybook { }
        InModuleScope WinPlaybook { Install-SshdDoWinPlaybook -ChavePublica 'ssh-ed25519 AAAA winplaybook' -Usuario 'eu' -Porta 47022 }
        $configuracao = Get-Content -LiteralPath (Join-Path $pasta 'sshd_config')
    }

    It 'escuta só no 127.0.0.1, na porta escolhida' {
        $configuracao | Should-ContainCollection 'Port 47022'
        $configuracao | Should-ContainCollection 'ListenAddress 127.0.0.1'
    }

    It 'aceita só a chave da distribuição, sem senha, para o usuário escolhido' {
        Get-Content -LiteralPath (Join-Path $pasta 'authorized_keys') | Should-Be 'ssh-ed25519 AAAA winplaybook'
        $configuracao | Should-ContainCollection 'PasswordAuthentication no'
        $configuracao | Should-ContainCollection 'AllowUsers "eu"'
    }

    It 'deixa a pasta só para o SYSTEM e os administradores' {
        Should-Invoke icacls.exe -ModuleName WinPlaybook -Scope Describe -ParameterFilter { ($args -join ' ') -like '*/inheritance:r /grant:r `*S-1-5-18:(OI)(CI)F `*S-1-5-32-544:(OI)(CI)F*' }
    }

    It 'tira da chave do servidor a permissão que o ssh-keygen dá ao usuário, que impede o serviço de iniciar' {
        Should-Invoke icacls.exe -ModuleName WinPlaybook -Scope Describe -ParameterFilter { ($args -join ' ') -like '*ssh_host_ed25519_key`* /reset' }
    }

    It 'cria e liga o serviço WinPlaybookSshd com a configuração própria' {
        Should-Invoke New-Service -ModuleName WinPlaybook -Scope Describe -Times 1 -Exactly -ParameterFilter { $Name -eq 'WinPlaybookSshd' -and $BinaryPathName -like '*sshd.exe" -f "*sshd_config"' -and $StartupType -eq 'Automatic' }
        Should-Invoke Start-Service -ModuleName WinPlaybook -Scope Describe -Times 1 -Exactly -ParameterFilter { $Name -eq 'WinPlaybookSshd' }
    }

    It 'mostra o que o sshd registrou quando o serviço não inicia' {
        Mock Start-Service -ModuleName WinPlaybook { throw 'falhou' }
        Mock Get-WinEvent -ModuleName WinPlaybook { [pscustomobject]@{ Message = 'error: Bad configuration option' } }

        { InModuleScope WinPlaybook { Install-SshdDoWinPlaybook -ChavePublica 'ssh-ed25519 AAAA winplaybook' -Usuario 'eu' -Porta 47022 } } | Should-Throw -ExceptionMessage '*WinPlaybookSshd não iniciou*Bad configuration option*'
    }
}
