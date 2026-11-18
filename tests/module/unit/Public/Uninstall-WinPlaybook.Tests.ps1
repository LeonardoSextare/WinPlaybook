BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Uninstall-WinPlaybook' {
    BeforeAll {
        Mock Get-PastaDeConfiguracao -ModuleName WinPlaybook { $pastaDeConfiguracao }
        Mock New-ExecutavelDeShim -ModuleName WinPlaybook { $null = New-Item -ItemType File -Path $Caminho -Value 'shim modelo' -Force }
        Mock New-ExecutavelDoRelay -ModuleName WinPlaybook { $null = New-Item -ItemType File -Path $Caminho -Value 'relay modelo' -Force }
        Mock Install-RelayDoAgenteSsh -ModuleName WinPlaybook { }
        Mock New-ExecutavelDoRelayDeRede -ModuleName WinPlaybook { $null = New-Item -ItemType File -Path $Caminho -Value 'relay de rede modelo' -Force }
        Mock Install-RelayDeRede -ModuleName WinPlaybook { }
        Mock Test-WslInstalado -ModuleName WinPlaybook { $true }
        Mock Get-DistribuicaoDoWsl -ModuleName WinPlaybook { 'WinPlaybook' }
        Mock Initialize-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Install-AnsibleNaDistribuicao -ModuleName WinPlaybook { }
        Mock Get-RaizDeMontagemDoWsl -ModuleName WinPlaybook { '/mnt/' }
        Mock Get-ComandoDoAnsible -ModuleName WinPlaybook { 'ansible', 'ansible-playbook' }
        Mock Get-CaminhoDoPowerShell -ModuleName WinPlaybook { 'C:\PowerShell\pwsh.exe' }
        Mock Add-EntradaNoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook { }
        Mock Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { }
        Mock Get-PastaDoSshDoUsuario -ModuleName WinPlaybook { $pastaDoSsh }
        Mock Get-PastaDoPerfilDoUsuario -ModuleName WinPlaybook { $pastaDoPerfil }
        Mock Get-NomeDoUsuarioDoWindows -ModuleName WinPlaybook { 'eu' }
        Mock Test-SessaoInterativa -ModuleName WinPlaybook { $false }
        Mock Get-PerfilDoPowerShell -ModuleName WinPlaybook { Join-Path $TestDrive 'perfis/PowerShell/profile.ps1'; Join-Path $TestDrive 'perfis/WindowsPowerShell/profile.ps1' }
        Mock Get-PastaDasExtensoesDoVSCode -ModuleName WinPlaybook { Join-Path $TestDrive 'sem-extensoes' }
    }

    BeforeEach {
        $pastaDeConfiguracao = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $pastaPadraoDosShims = Join-Path $pastaDeConfiguracao 'bin'
        $pastaDoSsh = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '-ssh')
        $pastaDoPerfil = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '-perfil')
    }

    Context 'quando a instalação criou a pasta .ssh do usuário' {
        BeforeEach {
            $null = Install-WinPlaybook
        }

        It 'apaga a pasta .ssh que continua vazia' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaDoSsh | Should-BeFalse
        }

        It 'mantém a pasta .ssh que recebeu arquivos' {
            $null = New-Item -ItemType File -Path (Join-Path $pastaDoSsh 'id_ed25519')

            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $pastaDoSsh 'id_ed25519') | Should-BeTrue
        }
    }

    Context 'quando o perfil do usuário tem as pastas do Ansible' {
        BeforeEach {
            $null = Install-WinPlaybook
            $pastaDasCollections = Join-Path $pastaDoPerfil '.ansible\collections'
            $pastaDasRoles = Join-Path $pastaDoPerfil '.ansible\roles'
            $null = New-Item -ItemType Directory -Path $pastaDasCollections, $pastaDasRoles -Force
        }

        It 'apaga as pastas vazias' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $pastaDoPerfil '.ansible') | Should-BeFalse
        }

        It 'mantém as collections instaladas' {
            $null = New-Item -ItemType File -Path (Join-Path $pastaDasCollections 'ansible_collections\comunidade\galaxy.yml') -Force

            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $pastaDasCollections 'ansible_collections\comunidade\galaxy.yml') | Should-BeTrue
            Test-Path -LiteralPath $pastaDasRoles | Should-BeFalse
        }
    }

    Context 'quando a pasta .ssh do usuário já existia na instalação' {
        BeforeEach {
            $null = New-Item -ItemType Directory -Path $pastaDoSsh
            $null = Install-WinPlaybook
        }

        It 'mantém a pasta .ssh vazia' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaDoSsh | Should-BeTrue
        }
    }

    Context 'quando o WinPlaybook está instalado na pasta padrão' {
        BeforeEach {
            $null = Install-WinPlaybook
        }

        It 'apaga a distribuição WinPlaybook e a pasta do disco dela' {
            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Nome -eq 'WinPlaybook' -and $Pasta -eq (Join-Path $pastaDeConfiguracao 'distro')
            }
        }

        It 'apaga a pasta dos shims' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeFalse
        }

        It 'tira a pasta dos shims do Path do usuário' {
            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Remove-EntradaDoPathDoUsuario -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Pasta -eq $pastaPadraoDosShims
            }
        }

        It 'apaga a configuração e a pasta de configuração' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaDeConfiguracao | Should-BeFalse
        }

        It 'desfaz as correções da extensão Ansible do VS Code' {
            $pastaDasExtensoes = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '-extensoes')
            $null = New-Item -ItemType Directory -Path (Join-Path $pastaDasExtensoes 'redhat.ansible-26.11.0')
            Mock Get-PastaDasExtensoesDoVSCode -ModuleName WinPlaybook { $pastaDasExtensoes }
            Mock Remove-PatchDaExtensaoAnsible -ModuleName WinPlaybook { }

            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Remove-PatchDaExtensaoAnsible -ModuleName WinPlaybook -Times 1 -Exactly -ParameterFilter {
                $Caminho -eq (Join-Path $pastaDasExtensoes 'redhat.ansible-26.11.0')
            }
        }
    }

    Context 'quando os shims estão numa pasta escolhida' {
        BeforeEach {
            $pastaEscolhida = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = Install-WinPlaybook -Path $pastaEscolhida
        }

        It 'apaga a pasta WinPlaybook criada dentro dela' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $pastaEscolhida 'WinPlaybook') | Should-BeFalse
        }

        It 'mantém a pasta escolhida' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath $pastaEscolhida | Should-BeTrue
        }
    }

    Context 'quando apagar a distribuição falha' {
        BeforeEach {
            $null = Install-WinPlaybook
            Mock Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook { throw 'a distribuição está em uso' }
        }

        It 'falha e mantém os shims' {
            { Uninstall-WinPlaybook -Confirm:$false } | Should-Throw -ExceptionMessage '*em uso*'

            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeTrue
        }
    }

    Context 'quando é chamado com -WhatIf' {
        BeforeEach {
            $null = Install-WinPlaybook
        }

        It 'mantém a distribuição e os shims' {
            Uninstall-WinPlaybook -WhatIf

            Should-Invoke Remove-DistribuicaoDoWinPlaybook -ModuleName WinPlaybook -Times 0 -Exactly
            Test-Path -LiteralPath $pastaPadraoDosShims | Should-BeTrue
        }
    }

    Context 'quando o comando é chamado' {
        It 'pede confirmação antes de apagar a distribuição' {
            $impacto = (Get-Command Uninstall-WinPlaybook).ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } | ForEach-Object { $_.ConfirmImpact }

            "$impacto" | Should-Be 'High'
        }
    }

    Context 'quando o autocomplete está ligado no perfil' {
        BeforeEach {
            Remove-Item -LiteralPath (Join-Path $TestDrive 'perfis') -Recurse -Force -ErrorAction SilentlyContinue
            $null = Install-WinPlaybook
            Add-Content -LiteralPath (Join-Path $TestDrive 'perfis/WindowsPowerShell/profile.ps1') -Value 'Set-Alias ll Get-ChildItem'
        }

        It 'apaga o perfil que só tinha a linha do autocomplete' {
            Uninstall-WinPlaybook -Confirm:$false

            Test-Path -LiteralPath (Join-Path $TestDrive 'perfis/PowerShell/profile.ps1') | Should-BeFalse
        }

        It 'mantém as outras linhas do perfil' {
            Uninstall-WinPlaybook -Confirm:$false

            @(Get-Content -LiteralPath (Join-Path $TestDrive 'perfis/WindowsPowerShell/profile.ps1')) | Should-BeCollection @('Set-Alias ll Get-ChildItem')
        }
    }

    Context 'quando o localhost_windows está ligado' {
        It 'desliga o localhost_windows antes de apagar o resto' {
            Mock Disable-WinPlaybookLocalhost -ModuleName WinPlaybook { }
            $null = Install-WinPlaybook

            Uninstall-WinPlaybook -Confirm:$false

            Should-Invoke Disable-WinPlaybookLocalhost -ModuleName WinPlaybook -Times 1 -Exactly
        }
    }
}
