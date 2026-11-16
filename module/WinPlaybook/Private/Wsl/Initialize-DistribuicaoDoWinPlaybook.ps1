function Initialize-DistribuicaoDoWinPlaybook {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL do WinPlaybook para rodar o Ansible, como o usuário winplaybook.

    .DESCRIPTION
    Grava o /etc/wsl.conf da distribuição, instala os programas que o Ansible usa (o Python,
    que roda os módulos num host com conexão local, o git, o ssh, o sshpass e o curl) e cria o
    usuário winplaybook, que passa a ser o padrão. A configuração vale depois que a
    distribuição reinicia, e por isso ela é parada no fim:

    - as unidades do Windows são montadas com metadata, pastas 755 e arquivos 644, como num
      disco do Linux. Assim o Ansible lê o ansible.cfg do projeto, um arquivo de senha do
      vault não vira script e o SSH aceita uma chave depois de um chmod 600;
    - o Path do Windows fica fora do PATH da distribuição;
    - o systemd fica desligado, e a distribuição inicia mais rápido;
    - o idioma é o C.UTF-8, que o Ansible exige.

    Rodar de novo deixa a distribuição no mesmo estado.

    .PARAMETER Nome
    O nome da distribuição no WSL.

    .EXAMPLE
    Initialize-DistribuicaoDoWinPlaybook -Nome 'WinPlaybook'

    .LINK
    https://learn.microsoft.com/windows/wsl/wsl-config#wslconf
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [string] $Nome
    )

    $script = @(
        'set -e;'
        'printf ''%s\n'' ''[boot]'' ''systemd=false'' '''' ''[automount]'' ''options="metadata,umask=22,fmask=111"'' '''' ''[interop]'' ''appendWindowsPath=false'' '''' ''[user]'' "default=$1" > /etc/wsl.conf;'
        'printf ''export LANG=C.UTF-8\n'' > /etc/profile.d/winplaybook.sh;'
        'export DEBIAN_FRONTEND=noninteractive;'
        'apt-get update -qq;'
        'apt-get install -y -qq --no-install-recommends ca-certificates curl git openssh-client python3 sshpass > /dev/null;'
        'id -u "$1" > /dev/null 2>&1 || useradd --create-home --shell /bin/bash "$1"'
    ) -join ' '

    $resultado = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script $script -Argumentos 'winplaybook' -Usuario 'root'
    $preparou = $resultado.CodigoDeSaida -eq 0
    if (-not $preparou) {
        throw (Get-Mensagem -Nome 'DistribuicaoNaoPreparada' -Valores $Nome, $resultado.Saida)
    }

    $ErrorActionPreference = 'Continue'
    $null = wsl --terminate $Nome 2>&1
}
