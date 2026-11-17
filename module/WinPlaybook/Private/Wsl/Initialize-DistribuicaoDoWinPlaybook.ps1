function Initialize-DistribuicaoDoWinPlaybook {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL do WinPlaybook para rodar o Ansible, como o usuário winplaybook.

    .DESCRIPTION
    Grava o /etc/wsl.conf e o /etc/fstab da distribuição, instala os programas que o Ansible
    usa (o Python, que roda os módulos num host com conexão local, o git, o ssh, o sshpass, o
    rsync, que o ansible.posix.synchronize usa, e o curl) e cria o usuário winplaybook, que
    passa a ser o padrão. A configuração vale depois que a distribuição reinicia, e por isso
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
    - o idioma é o C.UTF-8, que o Ansible exige.

    Rodar de novo deixa a distribuição no mesmo estado.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .PARAMETER PastaDoSsh
    A pasta .ssh do Windows, como C:\Users\<usuário>\.ssh.

    .EXAMPLE
    Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook' -PastaDoSsh 'C:\Users\<usuário>\.ssh'

    .LINK
    https://learn.microsoft.com/windows/wsl/wsl-config#wslconf
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome,
        [Parameter(Mandatory)] [string] $PastaDoSsh
    )

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
        'apt-get install -y -qq --no-install-recommends ca-certificates curl git openssh-client python3 rsync sshpass > /dev/null;'
        'printf ''HashKnownHosts no\n'' > /etc/ssh/ssh_config.d/winplaybook.conf;'
        'id -u "$1" > /dev/null 2>&1 || useradd --create-home --shell /bin/bash "$1";'
        'pasta_do_ssh="/home/$1/.ssh";'
        '[ -d "$pasta_do_ssh" ] || install -d -m 700 -o "$1" -g "$1" "$pasta_do_ssh";'
        'if [ -n "$2" ]; then printf ''%s %s drvfs metadata,uid=%s,gid=%s,umask=077,fmask=111 0 0\n'' "$2" "$pasta_do_ssh" "$(id -u "$1")" "$(id -g "$1")" > /etc/fstab; else : > /etc/fstab; fi'
    ) -join ' '

    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script $script -Argumentos 'winplaybook', $pastaDoSshNoFstab -Usuario 'root'
    $preparou = $resultado.CodigoDeSaida -eq 0
    if (-not $preparou) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoPreparada' -Valores $Nome, $resultado.Saida)
    }

    $ErrorActionPreference = 'Continue'
    $null = wsl --terminate $Nome 2>&1
}
