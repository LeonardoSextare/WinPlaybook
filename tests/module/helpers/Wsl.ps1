function Invoke-Wsl {
    <#
    .SYNOPSIS
    Executa o wsl.exe e devolve o código de saída (CodigoDeSaida) e a saída junto com os erros (Saida).

    .DESCRIPTION
    Uma linha no stderr não interrompe o comando, nem no Windows PowerShell 5.1.

    .PARAMETER Argumentos
    Os argumentos do wsl.exe.

    .EXAMPLE
    Invoke-Wsl -Argumentos '--list', '--quiet'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string[]] $Argumentos
    )

    $ErrorActionPreference = 'Continue'
    $saida = & wsl @Argumentos 2>&1 | ForEach-Object { "$_" }
    return [pscustomobject]@{
        CodigoDeSaida = $LASTEXITCODE
        Saida         = $saida -join [Environment]::NewLine
    }
}

function Initialize-DistribuicaoWslDeTeste {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL dos testes, com o Ansible e o ansible-lint, e devolve o nome dela.

    .DESCRIPTION
    A distribuição é a de WINPLAYBOOK_TEST_WSL_DISTRIBUTION ou, sem a variável, a
    WinPlaybookTest. Ela é criada quando ainda não existe e reaproveitada nas outras vezes.
    Na primeira vez, a preparação baixa o uv e o Ansible da internet.

    .EXAMPLE
    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $nome = $env:WINPLAYBOOK_TEST_WSL_DISTRIBUTION
    if (-not $nome) {
        $nome = 'WinPlaybookTest'
    }

    $utf8Original = $env:WSL_UTF8
    $env:WSL_UTF8 = '1'
    try {
        $nomesInstalados = (Invoke-Wsl -Argumentos '--list', '--quiet').Saida -split '\r?\n'
        $estaInstalada = $nomesInstalados -contains $nome
        if (-not $estaInstalada) {
            $resultado = Invoke-Wsl -Argumentos '--install', 'Ubuntu', '--name', $nome, '--no-launch'
            if ($resultado.CodigoDeSaida -ne 0) {
                throw "Não foi possível instalar a distribuição WSL ${nome}: $($resultado.Saida)"
            }
        }

        $comandosDePreparacao = @(
            'command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh'
            'uv tool install ansible-core'
            'uv tool install ansible-lint'
        )
        foreach ($comando in $comandosDePreparacao) {
            $resultado = Invoke-Wsl -Argumentos '-d', $nome, '-e', 'bash', '-lc', $comando
            if ($resultado.CodigoDeSaida -ne 0) {
                throw "Não foi possível rodar '$comando' na distribuição WSL ${nome}: $($resultado.Saida)"
            }
        }
    }
    finally {
        $env:WSL_UTF8 = $utf8Original
    }

    return $nome
}
