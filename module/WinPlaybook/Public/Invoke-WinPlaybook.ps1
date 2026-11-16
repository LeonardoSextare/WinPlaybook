function Invoke-WinPlaybook {
    <#
    .SYNOPSIS
    Executa um comando na distribuição WSL escolhida na instalação, a partir da pasta atual.

    .DESCRIPTION
    O primeiro argumento é o comando, e os outros vão para ele sem mudança, exceto os
    caminhos do Windows, que viram os caminhos deles na distribuição. O que chega pelo
    pipeline vai para a entrada padrão do comando, em UTF-8.

    .EXAMPLE
    Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml

    Executa o playbook na distribuição WSL.

    .EXAMPLE
    'segredo' | Invoke-WinPlaybook ansible-vault encrypt_string --stdin-name senha

    Cifra o texto que chega pelo pipeline.
    #>

    $temComando = $args.Count -gt 0
    if (-not $temComando) {
        throw (Get-Mensagem -Nome 'InformeOComando')
    }

    $argumentos = Get-ArgumentoDoShim -Comando $args[0] -Argumentos @($args | Select-Object -Skip 1) -CaminhoDoChamador $MyInvocation.PSCommandPath
    Invoke-ComandoNoWsl -Comando $args[0] -Argumentos @($argumentos) -Entrada @($input)
}
