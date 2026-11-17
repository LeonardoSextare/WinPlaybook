function Get-VariavelDoAnsible {
    <#
    .SYNOPSIS
    Devolve as variáveis de ambiente ANSIBLE_ do Windows que vão para a distribuição WSL, com os caminhos convertidos.

    .DESCRIPTION
    Pega as variáveis do processo cujo nome começa com ANSIBLE_, como o ANSIBLE_CONFIG e o
    ANSIBLE_STDOUT_CALLBACK, e converte os caminhos do Windows do valor com o
    ConvertTo-ValorDoWsl. Uma variável que já está no WSLENV fica de fora, porque o WSL a
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
    Get-VariavelDoAnsible -Distribuicao 'Ubuntu' -RaizDeMontagem '/mnt/' -PastaAtual 'C:\repo'

    Devolve @{ ANSIBLE_CONFIG = '/mnt/c/repo/ansible.cfg' } quando o ANSIBLE_CONFIG é C:\repo\ansible.cfg.

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

    $nomesNoWslenv = @("$env:WSLENV".Split(':') | ForEach-Object { $_.Split('/')[0] } | Where-Object { $_ })
    $variaveisDoProcesso = [Environment]::GetEnvironmentVariables('Process')

    $variaveis = @{}
    foreach ($nome in $variaveisDoProcesso.Keys) {
        $vaiParaOWsl = $nome.StartsWith('ANSIBLE_', [StringComparison]::Ordinal) -and ($nome -notin $nomesNoWslenv)
        if ($vaiParaOWsl) {
            $variaveis[$nome] = ConvertTo-ValorDoWsl -Valor $variaveisDoProcesso[$nome] -Distribuicao $Distribuicao -RaizDeMontagem $RaizDeMontagem -PastaAtual $PastaAtual -DestinoDeUnidade $DestinoDeUnidade
        }
    }

    return $variaveis
}
