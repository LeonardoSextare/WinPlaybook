function Get-VariavelDoWindows {
    <#
    .SYNOPSIS
    Devolve as variáveis de ambiente do Windows que vão para a distribuição WSL, com os caminhos convertidos.

    .DESCRIPTION
    Pega as variáveis do processo, como o ANSIBLE_CONFIG, o HTTPS_PROXY e as credenciais que
    as collections leem, e converte os caminhos do Windows do valor com o
    ConvertTo-ValorDoWsl. Ficam de fora as variáveis que o Linux da distribuição define do
    próprio jeito, como o PATH, o HOME, o TEMP e o LANG, as do Python e do agente SSH do
    Windows, as do próprio WSL e as que têm um nome que o Linux não aceita, como
    ProgramFiles(x86). Uma variável que já está no WSLENV também fica de fora, porque o WSL a
    passa do jeito que o usuário escolheu. Devolve uma hashtable com o nome e o valor
    convertido de cada variável.

    .PARAMETER Distribuicao
    A distribuição WSL onde o comando roda, como o wsl --list mostra.

    .PARAMETER RaizDeMontagem
    A pasta onde a distribuição monta as unidades do Windows, como /mnt/.

    .PARAMETER PastaAtual
    A pasta de onde o comando é executado, para os caminhos relativos.

    .PARAMETER DestinoDeUnidade
    A pasta real das unidades do subst e de rede, como Get-DestinoDeUnidade devolve. Um
    caminho numa dessas unidades vira o caminho da pasta real.

    .EXAMPLE
    Get-VariavelDoWindows -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve, entre outras, @{ ANSIBLE_CONFIG = '/mnt/c/repo/ansible.cfg' } quando o
    ANSIBLE_CONFIG é C:\repo\ansible.cfg.

    .LINK
    https://learn.microsoft.com/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] [string] $Distribuicao,
        [Parameter(Mandatory)] [string] $RaizDeMontagem,
        [Parameter(Mandatory)] [string] $PastaAtual,
        [hashtable] $DestinoDeUnidade = @{}
    )

    $nomesDoLinux = @(
        'PATH', 'PATHEXT', 'HOME', 'USER', 'LOGNAME', 'SHELL', 'TERM', 'PWD', 'OLDPWD', 'SHLVL', 'PS1'
        'TEMP', 'TMP', 'TMPDIR', 'LANG', 'LANGUAGE', 'DISPLAY', 'WAYLAND_DISPLAY'
        'PYTHONHOME', 'PYTHONPATH', 'VIRTUAL_ENV', 'SSH_AUTH_SOCK', 'SSH_AGENT_PID', 'WSLENV'
    )
    $prefixosDoLinux = @('LC_', 'XDG_', 'WSL_')
    $nomesNoWslenv = @("$env:WSLENV".Split(':') | ForEach-Object { $_.Split('/')[0] } | Where-Object { $_ })
    $variaveisDoProcesso = [Environment]::GetEnvironmentVariables('Process')

    $variaveis = @{}
    foreach ($nome in $variaveisDoProcesso.Keys) {
        $temNomeValidoNoLinux = $nome -match '^[A-Za-z_][A-Za-z0-9_]*$'
        $ehDoLinux = ($nome -in $nomesDoLinux) -or @($prefixosDoLinux | Where-Object { $nome.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
        $vaiParaOWsl = $temNomeValidoNoLinux -and -not $ehDoLinux -and ($nome -notin $nomesNoWslenv)
        if ($vaiParaOWsl) {
            $variaveis[$nome] = ConvertTo-ValorDoWsl -Valor $variaveisDoProcesso[$nome] -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual -DestinoDeUnidade $DestinoDeUnidade
        }
    }

    return $variaveis
}
