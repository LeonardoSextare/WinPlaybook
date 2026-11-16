function Initialize-DistribuicaoWslDeTeste {
    <#
    .SYNOPSIS
    Prepara a distribuição WSL dos testes, como o Install-WinPlaybook prepara a distribuição WinPlaybook, e devolve o nome dela.

    .DESCRIPTION
    A distribuição se chama WinPlaybookE2E e guarda o disco em
    %LOCALAPPDATA%\WinPlaybookTestes\WinPlaybookE2E. As funções do próprio módulo a criam e
    a preparam na primeira vez, com internet, e as outras vezes reaproveitam a distribuição
    já preparada. O módulo WinPlaybook precisa estar importado.

    .EXAMPLE
    $nomeDaDistribuicao = Initialize-DistribuicaoWslDeTeste
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $parametros = @{
        Nome  = 'WinPlaybookE2E'
        Pasta = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinPlaybookTestes\WinPlaybookE2E'
    }
    InModuleScope WinPlaybook -Parameters $parametros {
        $estaInstalada = $Nome -in @(Get-DistribuicaoDoWsl)
        if (-not $estaInstalada) {
            New-DistribuicaoDoWinPlaybook -Nome $Nome -Pasta $Pasta
        }

        $verificacao = Invoke-ScriptNaDistribuicao -Distribuicao $Nome -Script 'grep -qx "default=$1" /etc/wsl.conf && test -x "$HOME/.local/bin/ansible-playbook"' -Argumentos 'winplaybook' -Usuario 'winplaybook'
        $estaPreparada = $verificacao.CodigoDeSaida -eq 0
        if (-not $estaPreparada) {
            Initialize-DistribuicaoDoWinPlaybook -Nome $Nome
            Install-AnsibleNaDistribuicao -Nome $Nome -VersaoDoAnsible ''
        }
    }

    return $parametros.Nome
}
