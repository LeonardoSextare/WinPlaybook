BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
    Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Initialize-DistribuicaoDoWinPlaybook' {
    BeforeAll {
        Mock wsl -ModuleName WinPlaybook { }
        $pastaDoSshInexistente = Join-Path $TestDrive 'sem-perfil/.ssh'
    }

    Context 'quando a preparação funciona' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh }
        }

        It 'prepara a distribuição como root, para o usuário winplaybook' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'root' -and $Argumentos[0] -eq 'winplaybook'
            }
        }

        It 'configura a distribuição com <Descricao>' -ForEach @(
            @{ Descricao = 'as unidades do Windows montadas com as permissões de um disco do Linux'; Trecho = 'options="metadata,umask=22,fmask=111"' }
            @{ Descricao = 'o Path do Windows fora do PATH'; Trecho = 'appendWindowsPath=false' }
            @{ Descricao = 'o systemd desligado'; Trecho = 'systemd=false' }
            @{ Descricao = 'o idioma C.UTF-8'; Trecho = 'LANG=C.UTF-8' }
            @{ Descricao = 'o known_hosts gravado sem hash'; Trecho = '''HashKnownHosts no\n'' > /etc/ssh/ssh_config.d/winplaybook.conf' }
        ) {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script.Contains($Trecho) }
        }

        It 'instala o <_>' -ForEach @('python3', 'git', 'openssh-client', 'sshpass', 'rsync', 'socat', 'curl') {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script -match "apt-get install [^;]*\b$_\b" }
        }

        It 'para a distribuição, para a configuração valer no próximo comando' {
            Should-Invoke wsl -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { ($args -join ' ') -eq '--terminate WinPlaybook' }
        }
    }

    Context 'quando a pasta .ssh do Windows existe' {
        BeforeAll {
            $pastaDoSsh = Join-Path $TestDrive 'perfil com espaço/.ssh'
            $null = New-Item -ItemType Directory -Path $pastaDoSsh -Force
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSsh } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh }
        }

        It 'monta a pasta no ~/.ssh, com a barra e o espaço escritos como o fstab exige' {
            $pastaNoFstab = $pastaDoSsh.Replace('\', '\134').Replace(' ', '\040')

            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Argumentos[1] -eq $pastaNoFstab }
        }

        It 'monta a pasta com as permissões que o ssh exige' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script.Contains('drvfs metadata,uid=%s,gid=%s,umask=077,fmask=111') }
        }
    }

    Context 'quando a pasta .ssh do Windows não existe' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh }
        }

        It 'não monta nada no ~/.ssh' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Argumentos[1] -eq '' }
        }
    }

    Context 'quando a preparação falha' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 100; Saida = 'Temporary failure resolving deb.debian.org' } }
        }

        It 'explica o que conferir e mostra a resposta da distribuição' {
            { InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh } } | Should-Throw -ExceptionMessage '*preparar a distribuição WSL WinPlaybook*internet*Temporary failure resolving deb.debian.org'
        }

        It 'não para a distribuição' {
            { InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh } } | Should-Throw

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }
}
