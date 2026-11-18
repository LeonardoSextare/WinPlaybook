# Reportar um problema

Abra uma [issue no GitHub](https://github.com/LeonardoSextare/WinPlaybook/issues/new)
com o que aconteceu. Quanto mais do que está abaixo a issue tiver, mais rápido
o problema se resolve.

## O que mandar

1. O comando que você rodou e a saída completa, com a mensagem de erro.

2. As versões:

    ```powershell
    Get-Module WinPlaybook -ListAvailable | Select-Object Version
    $PSVersionTable.PSVersion
    wsl --version
    ansible --version
    ```

3. O log do comando, no nível `debug`. Rode o comando de novo assim:

    ```powershell
    $env:WINPLAYBOOK_LOG = 'debug'
    ansible-playbook site.yml
    ```

    E anexe as linhas do log desse momento. Veja [Consultar os logs](logs.md).

4. Se o problema acontece num _playbook_, um exemplo mínimo que o reproduza.

---

## Antes de mandar

!!! warning "Dados sensíveis"

    - Tire do log e da saída senhas, tokens e nomes internos que você não pode
      publicar. No nível `debug`, os argumentos dos comandos vão para o log.
    - Veja se o problema já está nas
      [issues abertas](https://github.com/LeonardoSextare/WinPlaybook/issues).
