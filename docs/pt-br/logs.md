# Consultar os logs

O WinPlaybook grava um log de cada comando, com o código de saída e o tempo de
cada etapa. Ele ajuda a entender um erro e a medir quanto tempo o WinPlaybook acrescenta
ao Ansible. Esta página mostra onde ficam os logs e como escolher o nível de
detalhe.

## Onde ficam

Os logs ficam em `%LOCALAPPDATA%\WinPlaybook\logs`, um arquivo por dia, como
`winplaybook-2026-11-18.log`. Os arquivos com mais de 7 dias são apagados, e o
`Uninstall-WinPlaybook` apaga a pasta.

```powershell
Get-Content "$env:LOCALAPPDATA\WinPlaybook\logs\winplaybook-$(Get-Date -Format yyyy-MM-dd).log" -Tail 20
```

---

## Escolher o nível de detalhe

A variável de ambiente `WINPLAYBOOK_LOG` define o nível:

| Nível   | O que grava                                                                   |
| ------- | ----------------------------------------------------------------------------- |
| `off`   | Nada                                                                          |
| `error` | Só os erros                                                                   |
| `info`  | Os erros e uma linha por comando, com o tempo de cada etapa (o padrão)        |
| `debug` | Também a pasta, os argumentos e o tempo de cada preparação na distribuição    |

Para a sessão atual do PowerShell:

```powershell
$env:WINPLAYBOOK_LOG = 'debug'
```

!!! warning "Senhas no log"

    No nível `debug`, os argumentos dos comandos vão para o log. Se você passa
    senhas nos argumentos, como num `-e senha=...`, volte para o `info` depois.

---

## Anexar a uma issue

Ao abrir uma issue, rode o comando que falha com o nível `debug` e anexe as
linhas do log desse momento. O log não guarda os valores das variáveis de
ambiente nem o conteúdo dos arquivos.
