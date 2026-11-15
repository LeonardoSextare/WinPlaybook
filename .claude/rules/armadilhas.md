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
  externos. Os argumentos passam por `ConvertTo-LegacyNativeArgument` quando
  `Test-LegacyArgumentPassing` é verdadeiro.
- No 5.1, com o stderr redirecionado e `Stop` no escopo global, a primeira
  linha de aviso de um programa interrompe o comando. Antes de chamar o
  programa, defina `$ErrorActionPreference = 'Continue'` dentro da função que
  o chama, sem `$global:` nem `$script:`. Assim a mudança vale só para essa
  função e não altera a sessão do usuário. Decida se o programa falhou pelo
  `$LASTEXITCODE`, não pelo stderr.

## WSL

- O `wsl.exe` escreve as próprias mensagens em UTF-16. Para ler a saída dele,
  defina `$env:WSL_UTF8 = '1'` e restaure o valor original no `finally`.

## Ansible

- Numa função avançada, o `-i` do Ansible vira um parâmetro ambíguo do
  PowerShell. A função que repassa argumentos ao Ansible é simples, sem
  `[CmdletBinding()]` nem `param()`, e usa `$args`.

## Shims

- Chamado pelo `.exe` com `-File`, o PowerShell sai com 0 mesmo quando o
  comando falha. O `.ps1` gerado para cada shim termina com
  `exit $LASTEXITCODE`.

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
