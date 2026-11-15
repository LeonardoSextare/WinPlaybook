function Invoke-WinPlaybook {
    <#
    .SYNOPSIS
    Executa um comando na distribuição WSL escolhida na instalação, a partir da pasta atual.

    .DESCRIPTION
    O primeiro argumento é o comando, e os outros vão para ele sem mudança, exceto os
    caminhos do Windows, que viram os caminhos deles na distribuição.

    .EXAMPLE
    Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml

    Executa o playbook na distribuição WSL.
    #>

    $temComando = $args.Count -gt 0
    if (-not $temComando) {
        throw 'Informe o comando que vai rodar na distribuição WSL, por exemplo: Invoke-WinPlaybook ansible --version'
    }

    Invoke-ComandoNoWsl -Comando $args[0] -Argumentos @($args | Select-Object -Skip 1)
}
