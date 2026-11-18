function Get-ComandoDoAnsible {
    <#
    .SYNOPSIS
    Lista os comandos que o ambiente do Ansible instala numa distribuição WSL.

    .DESCRIPTION
    São os comandos de ~/.local/bin que o uv liga ao ambiente do Ansible: os do Ansible, os
    do ansible-lint e os dos pacotes Python extras, como o molecule. Os outros programas da
    distribuição, inclusive os que vêm como dependência desses pacotes, ficam de fora.

    .PARAMETER Distribuicao
    A distribuição WSL, como o wsl --list mostra.

    .EXAMPLE
    Get-ComandoDoAnsible -Distribuicao 'WinPlaybook'

    Devolve ansible, ansible-config, ansible-lint, ansible-playbook, os outros comandos do
    Ansible e os dos pacotes extras.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao
    )

    $script = 'for comando in "$HOME"/.local/bin/*; do case $(readlink -f "$comando") in "$HOME"/.local/share/uv/tools/ansible/*) printf "%s\n" "${comando##*/}";; esac; done'
    $argumentosDoWsl = @('--distribution', $Distribuicao, '--exec', 'sh', '-c', $script)

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $ErrorActionPreference = 'Continue'
    $listagem = wsl @argumentosDoWsl

    $listou = $LASTEXITCODE -eq 0
    if (-not $listou) {
        throw (Get-Mensagem -Nome 'ComandosNaoListados' -Valores $Distribuicao, $LASTEXITCODE)
    }

    $comandos = @($listagem | Where-Object { $_ } | Sort-Object -Unique)

    $temComandosDoAnsible = @($comandos | Where-Object { $_.StartsWith('ansible') }).Count -gt 0
    if (-not $temComandosDoAnsible) {
        throw (Get-Mensagem -Nome 'DistribuicaoSemAnsible' -Valores $Distribuicao)
    }

    return $comandos
}
