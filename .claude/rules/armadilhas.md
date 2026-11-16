---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---

# Armadilhas

Comportamentos do PowerShell, do Windows e das ferramentas que já causaram
bugs, e como o código lida com cada um.

## Como registrar

- Quando um bug revela uma armadilha nova, ela entra aqui no mesmo commit da
  correção.
- Cada armadilha diz o que acontece e o que o código faz para evitar.
- Cada armadilha tem um teste que falha se o problema voltar ao código.
- As armadilhas ficam agrupadas por assunto. Um assunto novo ganha uma seção
  própria.

## Windows PowerShell 5.1

- O 5.1 não escapa as aspas internas dos argumentos passados a programas
  externos. Os argumentos passam por `ConvertTo-ArgumentoNativoLegado` quando
  `Test-PassagemDeArgumentosLegada` é verdadeiro.
- No 5.1, com o stderr redirecionado e `Stop` no escopo global, a primeira
  linha de aviso de um programa interrompe o comando. Antes de chamar o
  programa, defina `$ErrorActionPreference = 'Continue'` dentro da função que
  o chama, sem `$global:` nem `$script:`. Assim a mudança vale só para essa
  função e não altera a sessão do usuário. Decida se o programa falhou pelo
  `$LASTEXITCODE`, não pelo stderr.
- O 5.1 lê um `.ps1`, `.psm1` ou `.psd1` sem BOM como ANSI, e os acentos viram
  lixo (`não` vira `nÃ£o`). Arquivo do módulo ou dos testes com texto não
  ASCII é gravado em UTF-8 com BOM. O `tests/module/unit/Codificacao.Tests.ps1`
  confere todos.
- No 5.1, o `Get-ChildItem -LiteralPath` ignora o `-Include` e devolve todos
  os arquivos. Filtre pela extensão com `Where-Object`
  (`$_.Extension -in '.ps1', '.psd1'`).
- No 5.1, o `Test-Path` escreve o erro "Caracteres inválidos no caminho"
  quando o caminho tem `"`, `<`, `>` ou `|`, como um argumento com JSON, e o
  erro interrompe o comando de quem para nos erros. Antes de testar se um
  argumento é um caminho, confira se ele não tem os caracteres de
  `[IO.Path]::GetInvalidPathChars()`.

## WSL

- O `wsl.exe` escreve as próprias mensagens em UTF-16, como o erro de uma
  distribuição que não existe, e elas aparecem com espaços entre as letras no
  meio da saída em UTF-8 do Linux. Para ler a saída dele, e também ao rodar o
  comando do usuário, defina `$env:WSL_UTF8 = '1'` e restaure o valor original
  no `finally`.
- O PowerShell decodifica a saída de um programa com o
  `[Console]::OutputEncoding`, que no Windows é a página de código OEM (850 em
  português), e a saída em UTF-8 do Linux perde os acentos quando o PowerShell
  a captura. O `Invoke-ComandoNoWsl` usa UTF-8 no console enquanto o `wsl`
  roda e restaura o valor original no `finally`.

## Ansible

- Numa função avançada, o `-i` do Ansible vira um parâmetro ambíguo do
  PowerShell. A função que repassa argumentos ao Ansible é simples, sem
  `[CmdletBinding()]` nem `param()`, e usa `$args`.
- O WSL monta as unidades do Windows com escrita para todos (777), e o Ansible
  ignora o `ansible.cfg` de uma pasta assim. O script do
  `Invoke-ComandoNoWsl` põe o `ansible.cfg` da pasta atual no
  `ANSIBLE_CONFIG` quando a pasta tem escrita para todos e a variável não está
  definida.

## Shims

- Aberto com `-File`, o PowerShell trata como parâmetro do script o argumento
  que começa com `-` e tem `:`. O PowerShell 7 separa
  `--inventory=C:\hosts.yml` em `--inventory=C` e `\hosts.yml`, e as duas
  edições separam `-i:valor`. O `Invoke-WinPlaybook` pega os argumentos do
  processo (`Get-ArgumentoDoShim`), que chegam intactos, quando o shim foi
  aberto pelo `.exe`.
- Chamado pelo `.exe` com `-File`, o PowerShell sai com 0 mesmo quando o
  comando falha. O `.ps1` gerado para cada shim termina com
  `exit $LASTEXITCODE`.
- Aberto com `-File` e com a entrada padrão redirecionada, o PowerShell lê a
  entrada para o `$input` do script quando ele cita `$input`, mesmo num trecho
  que não roda, e o programa que o script chama recebe a entrada vazia. O
  `.exe` abre o `exe\<comando>.ps1`, que não cita `$input`. Só o `.ps1` que o
  PowerShell executa repassa o pipeline.
- O PowerShell escreve cada linha do pipeline na entrada de um programa com
  `\r\n`, e o 5.1 pode pôr um BOM no começo, mesmo com o `$OutputEncoding` em
  UTF-8 sem BOM. O `Invoke-ComandoNoWsl` manda o pipeline em UTF-8, e o script
  na distribuição tira o BOM e os `\r` com o `sed`.

## Caminhos e texto

- `-Path` interpreta colchetes como curinga. Cmdlets que acessam arquivos
  (`Test-Path`, `Get-Item`, `Get-Content`...) recebem caminhos por
  `-LiteralPath`. Cmdlets que só manipulam texto (`Split-Path`, `Join-Path`)
  usam `-Path`, que não procura arquivos.
- Num padrão de `-like`, `-match` ou `-replace`, colchetes viram curinga e `\`
  vira escape de regex. Texto vindo do usuário nunca vira padrão: use métodos
  de string (`.Replace()`, `.StartsWith()`, `.Substring()`). Ele pode ser o
  alvo de um padrão escrito no código (`$valor -replace '(\\*)"', ...`).
- Os operadores de comparação (`-eq`, `-ne`) ignoram maiúsculas, mas os
  métodos de string não. Métodos que comparam texto recebem
  `[StringComparison]::OrdinalIgnoreCase`.

## Arquivos do módulo

- Um caminho montado a partir do `$PSScriptRoot` depende da subpasta onde a
  função está. Ao mover o arquivo, ajuste o caminho relativo.

## Pester

- O Pester faz mock de funções, não de métodos do .NET. Uma chamada a método
  estático que os testes precisam simular fica numa função privada própria.
