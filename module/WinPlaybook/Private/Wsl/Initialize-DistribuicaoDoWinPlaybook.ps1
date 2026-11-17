function Initialize-DistribuicaoDoWinPlaybook {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL do WinPlaybook para rodar o Ansible, como o usuário winplaybook.

    .DESCRIPTION
    Grava o /etc/wsl.conf e o /etc/fstab da distribuição, instala os programas que o Ansible
    usa (o Python, que roda os módulos num host com conexão local, o git, o ssh, o sshpass, o
    rsync, que o ansible.posix.synchronize usa, o socat, que liga o ssh ao agente SSH do
    Windows, e o curl) e cria o usuário winplaybook, que passa a ser o padrão. A configuração vale depois que a distribuição reinicia, e por isso
    ela é parada no fim:

    - as unidades do Windows são montadas com metadata, pastas 755 e arquivos 644, como num
      disco do Linux. Assim o Ansible lê o ansible.cfg do projeto, e um arquivo de senha do
      vault não vira script;
    - a pasta .ssh do Windows, quando existe, vira o ~/.ssh do usuário winplaybook, com a
      pasta 700 e os arquivos 600, como o ssh exige. Assim o ssh usa as chaves, o
      known_hosts e o config do Windows, sem cópias e sem mudar as permissões dos arquivos
      no Windows. Quando ela não existe, a distribuição usa um ~/.ssh próprio;
    - o ssh grava os hosts novos no known_hosts sem hash, como o ssh do Windows. Um
      HashKnownHosts no config do ~/.ssh continua valendo;
    - o Path do Windows fica fora do PATH da distribuição;
    - o systemd fica desligado, e a distribuição inicia mais rápido;
    - o idioma é o C.UTF-8, que o Ansible exige;
    - o ssh conecta com o nome do usuário do Windows quando a conexão não define um usuário,
      como o ssh do Windows;
    - o Ansible usa o .ansible.cfg do perfil do Windows e guarda as collections e as roles
      que o ansible-galaxy instala nas pastas .ansible\collections e .ansible\roles do
      perfil. As que já estavam na distribuição vão para essas pastas.

    Rodar de novo deixa a distribuição no mesmo estado.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .PARAMETER PastaDoSsh
    A pasta .ssh do Windows, como C:\Users\<usuário>\.ssh.

    .PARAMETER PastaDoPerfil
    A pasta do perfil do usuário no Windows, como C:\Users\<usuário>.

    .PARAMETER UsuarioDoWindows
    O nome do usuário do Windows.

    .EXAMPLE
    Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh 'C:\Users\eu\.ssh' -PastaDoPerfil 'C:\Users\eu' -UsuarioDoWindows 'eu'

    .LINK
    https://learn.microsoft.com/windows/wsl/wsl-config#wslconf
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $PastaDoSsh,
        [Parameter(Mandatory)] [string] $PastaDoPerfil,
        [Parameter(Mandatory)] [string] $UsuarioDoWindows
    )

    $pastaDoAnsible = Join-Path -Path $PastaDoPerfil -ChildPath '.ansible'
    foreach ($pasta in 'collections', 'roles') {
        $null = New-Item -ItemType Directory -Path (Join-Path -Path $pastaDoAnsible -ChildPath $pasta) -Force
    }

    $pastaDoSshNoFstab = ''
    $pastaDoSshExiste = Test-Path -LiteralPath $PastaDoSsh -PathType Container
    if ($pastaDoSshExiste) {
        $pastaDoSshNoFstab = $PastaDoSsh.Replace('\', '\134').Replace(' ', '\040')
    }

    $script = @(
        'set -e;'
        'printf ''%s\n'' ''[boot]'' ''systemd=false'' '''' ''[automount]'' ''options="metadata,umask=22,fmask=111"'' '''' ''[interop]'' ''appendWindowsPath=false'' '''' ''[user]'' "default=$1" > /etc/wsl.conf;'
        'printf ''export LANG=C.UTF-8\n'' > /etc/profile.d/winplaybook.sh;'
        'export DEBIAN_FRONTEND=noninteractive;'
        'apt-get update -qq;'
        'apt-get install -y -qq --no-install-recommends ca-certificates curl git openssh-client python3 rsync socat sshpass > /dev/null;'
        'printf ''HashKnownHosts no\nUser "%s"\n'' "$3" > /etc/ssh/ssh_config.d/winplaybook.conf;'
        'id -u "$1" > /dev/null 2>&1 || useradd --create-home --shell /bin/bash "$1";'
        'pasta_do_ssh="/home/$1/.ssh";'
        '[ -d "$pasta_do_ssh" ] || install -d -m 700 -o "$1" -g "$1" "$pasta_do_ssh";'
        'if [ -n "$2" ]; then printf ''%s %s drvfs metadata,uid=%s,gid=%s,umask=077,fmask=111 0 0\n'' "$2" "$pasta_do_ssh" "$(id -u "$1")" "$(id -g "$1")" > /etc/fstab; else : > /etc/fstab; fi;'
        'perfil=$(wslpath -a "$4");'
        'pasta_do_ansible="/home/$1/.ansible";'
        'install -d -o "$1" -g "$1" "$pasta_do_ansible";'
        'for pasta in collections roles; do'
        'if [ -d "$pasta_do_ansible/$pasta" ] && [ ! -L "$pasta_do_ansible/$pasta" ]; then cp -r "$pasta_do_ansible/$pasta/." "$perfil/.ansible/$pasta/"; rm -rf "$pasta_do_ansible/$pasta"; fi;'
        'ln -sfn "$perfil/.ansible/$pasta" "$pasta_do_ansible/$pasta";'
        'done;'
        'ln -sfn "$perfil/.ansible.cfg" "/home/$1/.ansible.cfg"'
    ) -join ' '

    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script $script -Argumentos 'winplaybook', $pastaDoSshNoFstab, $UsuarioDoWindows, $PastaDoPerfil -Usuario 'root'
    $preparou = $resultado.CodigoDeSaida -eq 0
    if (-not $preparou) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoPreparada' -Valores $Nome, $resultado.Saida)
    }

    $ErrorActionPreference = 'Continue'
    $null = wsl --terminate $Nome 2>&1
}
