function Get-ComandoDoAnsible {
    <#
    .SYNOPSIS
    Lista os comandos do Ansible que estão no PATH de uma distribuição WSL.

    .DESCRIPTION
    Lê o PATH de um login shell, que tem as pastas do usuário, como ~/.local/bin. As pastas
    das unidades do Windows ficam de fora, porque o WSL acrescenta o Path do Windows à
    distribuição, e ele tem os shims do WinPlaybook.

    .PARAMETER Distribuicao
    A distribuição WSL, como o wsl --list mostra.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .EXAMPLE
    Get-ComandoDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/'

    Devolve ansible, ansible-config, ansible-lint, ansible-playbook e os outros comandos do Ansible.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $RaizDeMontagem
    )

    $script = 'raiz_de_montagem="$0"; IFS=:; for pasta in $PATH; do case $pasta in "$raiz_de_montagem"*) ;; *) ls "$pasta" 2>/dev/null || : ;; esac; done'
    $argumentosDoWsl = @('--distribution', $Distribuicao, '--exec', 'sh', '-lc', $script, $RaizDeMontagem)

    $ehPassagemLegada = Test-PassagemDeArgumentosLegada
    if ($ehPassagemLegada) {
        $argumentosDoWsl = @(ConvertTo-ArgumentoNativoLegado -Argumento $argumentosDoWsl)
    }

    $ErrorActionPreference = 'Continue'
    $listagem = wsl @argumentosDoWsl

    $listou = $LASTEXITCODE -eq 0
    if (-not $listou) {
        throw "Não foi possível listar os comandos da distribuição WSL $Distribuicao (código de saída do wsl: $LASTEXITCODE)."
    }

    $comandos = @($listagem | Where-Object { $_.StartsWith('ansible') } | Sort-Object -Unique)

    $temComandos = $comandos.Count -gt 0
    if (-not $temComandos) {
        throw "A distribuição WSL $Distribuicao não tem comandos do Ansible. Instale o Ansible nela e tente de novo."
    }

    return $comandos
}
