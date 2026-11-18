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
        Mock Get-UnidadeFixa -ModuleName WinPlaybook { 'c', 'd' }
        $pastaDoSshInexistente = Join-Path $TestDrive 'sem-perfil/.ssh'
        $pastaDoPerfil = Join-Path $TestDrive 'perfil-do-windows'
    }

    Context 'quando a preparação funciona' {
        BeforeAll {
            Mock Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook { [pscustomobject]@{ CodigoDeSaida = 0; Saida = '' } }
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente; PastaDoPerfil = $pastaDoPerfil } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'Leonardo Silva' }
        }

        It 'prepara a distribuição como root, para o usuário winplaybook' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Distribuicao -eq 'WinPlaybook' -and $Usuario -eq 'root' -and $Argumentos[0] -eq 'winplaybook'
            }
        }

        It 'configura a distribuição com <Descricao>' -ForEach @(
            @{ Descricao = 'as unidades do Windows montadas com as permissões de um disco do Linux'; Trecho = 'options="metadata,umask=22,fmask=111"' }
            @{ Descricao = 'o Path do Windows fora do PATH do WSL'; Trecho = 'appendWindowsPath=false' }
            @{ Descricao = 'o systemd desligado'; Trecho = 'systemd=false' }
            @{ Descricao = 'o idioma C.UTF-8'; Trecho = 'LANG=C.UTF-8' }
            @{ Descricao = 'o known_hosts gravado sem hash'; Trecho = '''HashKnownHosts no\n' }
            @{ Descricao = 'o usuário do Windows como padrão do ssh'; Trecho = 'User "%s"\n'' "$3" > /etc/ssh/ssh_config.d/winplaybook.conf' }
            @{ Descricao = 'o .ansible.cfg do perfil do Windows'; Trecho = 'ln -sfn "$perfil/.ansible.cfg" "/home/$1/.ansible.cfg"' }
            @{ Descricao = 'as collections e as roles no perfil do Windows'; Trecho = 'ln -sfn "$perfil/.ansible/$pasta" "$pasta_do_ansible/$pasta"' }
            @{ Descricao = 'as collections que já estavam na distribuição levadas para o perfil'; Trecho = 'cp -r "$pasta_do_ansible/$pasta/." "$perfil/.ansible/$pasta/"' }
            @{ Descricao = 'cada unidade fixa montada de novo com execução, sem travar o boot quando ela some'; Trecho = '/opt/winplaybook/exec/%s drvfs uid=%s,gid=%s,umask=22,nofail 0 0' }
            @{ Descricao = 'os .bat e .cmd executados pelo cmd.exe'; Trecho = 'exec "$cmd_do_windows" /d /c "$(wslpath -w "$programa")" "$@"' }
            @{ Descricao = 'os caminhos da distribuição nos argumentos dos programas do Windows convertidos'; Trecho = 'case "$argumento" in /mnt/*|/home/*|/tmp/*) argumento=$(wslpath -w "$argumento"' }
            @{ Descricao = 'o ssh que usa a cópia traduzida do config do ssh'; Trecho = '[ -f "$configuracao" ] && exec /usr/bin/ssh -F "$configuracao" "$@"' }
        ) {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script.Contains($Trecho) }
        }

        It 'passa ao script o cmd.exe do Windows e as unidades fixas' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Argumentos[4] -like '/opt/winplaybook/exec/?/*/cmd.exe' -and ($Argumentos[5..($Argumentos.Count - 1)] -join ',') -eq 'c,d'
            }
        }

        It 'passa o usuário e a pasta do perfil do Windows ao script' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Argumentos[2] -eq 'Leonardo Silva' -and $Argumentos[3] -eq $pastaDoPerfil
            }
        }

        It 'cria no perfil do Windows a pasta <_>' -ForEach '.ansible\collections', '.ansible\roles' {
            Test-Path -LiteralPath (Join-Path $pastaDoPerfil $_) -PathType Container | Should-BeTrue
        }

        It 'instala o <_>' -ForEach @('python3', 'git', 'openssh-client', 'sshpass', 'rsync', 'socat', 'curl', 'nftables', 'libcap2-bin') {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter { $Script -match "apt-get install [^;]*\b$_\b" }
        }

        It 'dá ao usuário winplaybook uma cópia do nft com a capability CAP_NET_ADMIN' {
            Should-Invoke Invoke-ScriptNaDistribuicao -ModuleName WinPlaybook -Scope Context -Times 1 -Exactly -ParameterFilter {
                $Script.Contains('install -m 750 -g "$1" /usr/sbin/nft /usr/local/lib/winplaybook/nft;') -and $Script.Contains('setcap cap_net_admin+ep /usr/local/lib/winplaybook/nft;')
            }
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
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSsh; PastaDoPerfil = $pastaDoPerfil } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'Leonardo Silva' }
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
            InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente; PastaDoPerfil = $pastaDoPerfil } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'Leonardo Silva' }
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
            { InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente; PastaDoPerfil = $pastaDoPerfil } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'Leonardo Silva' } } | Should-Throw -ExceptionMessage '*preparar a distribuição WSL WinPlaybook*internet*Temporary failure resolving deb.debian.org'
        }

        It 'não para a distribuição' {
            { InModuleScope WinPlaybook -Parameters @{ PastaDoSsh = $pastaDoSshInexistente; PastaDoPerfil = $pastaDoPerfil } { Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh $PastaDoSsh -PastaDoPerfil $PastaDoPerfil -UsuarioDoWindows 'Leonardo Silva' } } | Should-Throw

            Should-Invoke wsl -ModuleName WinPlaybook -Times 0 -Exactly
        }
    }
}
