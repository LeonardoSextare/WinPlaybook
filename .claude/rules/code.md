---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---

# Código

## Nomenclatura

### Geral

- Os nomes são claros, diretos e descritivos. Quem lê o nome entende o que
  a variável guarda ou o que a função faz, sem precisar ler o código ao redor.
- Os nomes são em português, com os termos técnicos em inglês quando esse é o
  uso comum (`$pastaDosShims`, `$caminhoDoExe`).
- Identificadores não têm acentos nem `ç`: `$configuracao`, nunca
  `$configuração`.
- Abreviações comuns são bem-vindas (`$exe`, `$url`), desde que não enganem.
- A API pública fica em inglês, porque mudar um nome dela quebra quem já usa
  o módulo: os comandos públicos e os parâmetros deles, as propriedades dos
  objetos que eles devolvem, as chaves do `settings.json` e as variáveis de
  ambiente `WINPLAYBOOK_*`.
- As mensagens que o código mostra, como os erros e as ações do `-WhatIf`,
  ficam nos `Mensagens.psd1` de cada idioma (`pt-BR/` e `en-US/`, na pasta do
  módulo), sempre com as mesmas chaves, e o código as pega com `Get-Mensagem`.
  O usuário as vê no idioma da interface do Windows, com o inglês como
  reserva. Uma mensagem nova entra nos dois arquivos no mesmo commit.
- A ajuda baseada em comentário, inclusive a dos comandos públicos, e os nomes
  dos testes ficam em português.

### Variáveis

- Variáveis em camelCase (`$caminhoDoShim`) e parâmetros em PascalCase
  (`-CaminhoDoShim`).
- Uma variável com um caminho é `$caminhoDoShim`, não `$shim`.
- Booleanos são perguntas de sim ou não: `$estaInstalado`, `$temComando`.
- Um valor que vai para um parâmetro de cmdlet usa o nome desse parâmetro
  (`$FilePath` para o `-FilePath` do `Start-Process`).
- Uma variável nunca repete o nome de um parâmetro com outra caixa: `$path` e
  `$Path` são a mesma variável.

### Funções e arquivos

Todas as funções:

- Usam verbos aprovados (`Get-Verb`) e substantivo no singular, mesmo quando
  devolvem vários itens (`Get-Process`).
- Ficam num arquivo próprio, com o nome da função (`Get-PastaDeConfiguracao.ps1`).

Funções públicas:

- Nome em inglês, com `WinPlaybook` no substantivo (`Install-WinPlaybook`).
- Parâmetros em inglês, com os nomes que o PowerShell já usa para a mesma
  ideia (`-Path`, `-Force`).

Funções privadas:

- Substantivo em português, sem `WinPlaybook` (`Get-PastaDeConfiguracao`).
- Parâmetros em português (`-PastaAtual`).

## Comentários e ajuda

- O código não tem comentários. Quando um trecho precisa de explicação, ele
  vira uma função ou uma variável cujo nome diga o que ele faz.
- Toda função tem ajuda baseada em comentário, no começo do corpo.
- A ajuda fala com quem chama a função: o que ela faz, o que recebe, o que
  devolve e como se usa. Ela não explica a implementação, não justifica
  decisões e não guarda histórico nem pendências.
- A ajuda usa só estas seções: `.SYNOPSIS` (uma frase), `.DESCRIPTION`
  (o comportamento que quem chama precisa conhecer), `.PARAMETER`, `.EXAMPLE`
  (pelo menos um) e `.LINK` (documentação oficial do que a função usa).

## Edições do PowerShell

- O módulo e os testes rodam no Windows PowerShell 5.1 e no PowerShell 7.
  Tudo o que eles usam, seja cmdlet, parâmetro, operador, sintaxe ou API do
  .NET, existe nas duas edições.
- Os demais scripts rodam só no PowerShell 7 e começam com
  `#Requires -Version 7.4`. São os scripts do CI, do release e do
  desenvolvimento, e qualquer script simples que não faz parte do módulo.

## Módulo

- Uma função privada fica na subpasta de `Private/` do assunto dela.
  `Utility/` só recebe o que não pertence a nenhum assunto, e uma subpasta
  nova só surge com um assunto novo.
- O `.psm1` não recebe funções nem lógica além do `Set-StrictMode` e do
  dot-sourcing.
- No repositório, cada função fica num arquivo próprio, e o código não tem
  partes geradas. O pacote publicado junta as funções de `Private/` e
  `Public/` num `.psm1` só (`scripts/Build-PacoteDoModulo.ps1`), porque o
  PowerShell carrega um arquivo grande bem mais rápido que dezenas de arquivos
  pequenos, e cada shim `.exe` carrega o módulo de novo. Nada além disso muda
  no pacote, e o CI roda os testes no código e no pacote.
- O módulo nunca reescreve os próprios arquivos nem gera funções em tempo de
  execução.
- O `ModuleVersion` do manifesto fica em `'0.0.0'` e não é alterado.
- As listas de exportação do manifesto são explícitas (`@()` quando vazias),
  nunca `*`.
- Ao criar, renomear ou remover uma função pública, o `FunctionsToExport` muda
  no mesmo commit.
- O módulo não exporta os comandos do Ansible, nem como função nem como
  alias.

## Funções

- Toda função tem `[CmdletBinding()]` e `[OutputType()]`. A exceção é a
  função que repassa argumentos ao Ansible (veja `armadilhas.md`).
- Chamadas entre funções do módulo usam parâmetros nomeados.
- A função devolve o valor com `return`, também na última linha
  (`return $caminhoDoShim`), nunca com um valor solto.
- Dentro de laços, cada valor devolvido usa `Write-Output`. Ele funciona como
  um `return` que não sai da função: entrega o valor a quem chamou e o laço
  continua.
- No PowerShell, todo valor que não é capturado vira retorno. Uma saída que
  não faz parte do retorno é descartada com `$null =`.
- Uma condição que não é trivial vai para uma variável com nome, declarada
  logo antes do `if` que a usa, sem linha em branco entre as duas.
- Variáveis auxiliares ficam perto do código que as usa, não no topo da
  função.

## Erros

- Fail fast: quando algo impede o comando de continuar, a função para na
  hora com um `throw` e um erro claro.
- A mensagem diz o que aconteceu e o que o usuário pode fazer, com o comando
  quando houver um (`Instale com: wsl --install`).
- Quando uma página ajuda a resolver o erro, como a documentação oficial da
  ferramenta ou a do WinPlaybook, a mensagem traz o link.
- A mensagem mostra o valor como o usuário passou, não a versão normalizada.

## Sistema do usuário

- Todo comando público que altera o sistema declara
  `[CmdletBinding(SupportsShouldProcess)]` e chama
  `$PSCmdlet.ShouldProcess()` antes da primeira alteração. Os dois juntos dão
  ao usuário o `-WhatIf` e o `-Confirm`.
- Um comando faz primeiro as etapas que podem falhar, como validar os
  parâmetros e consultar o WSL, e só depois apaga ou grava algo. Assim, uma
  falha não deixa o sistema pela metade.
- O WinPlaybook só cria e apaga pastas dele. Os shims ficam em
  `<local>\WinPlaybook\bin` (padrão `%LOCALAPPDATA%\WinPlaybook\bin`). Uma
  pasta já existente que não está registrada na configuração não é tocada.
- No perfil do usuário, o WinPlaybook cria só as pastas `.ansible\collections` e
  `.ansible\roles`, que o Ansible usa como no Windows, e a desinstalação as apaga
  só se continuarem vazias.
- A única distribuição WSL que o WinPlaybook cria, altera e apaga é a dele, a
  `WinPlaybook`, com o disco em `%LOCALAPPDATA%\WinPlaybook\distro`. As
  distribuições do usuário não são tocadas.
- O `~/.ssh` da distribuição é a pasta `.ssh` do perfil do usuário no
  Windows, montada. Quando ela não existe, a instalação a cria vazia, e a
  desinstalação a apaga se ela continuar vazia. Fora isso, o WinPlaybook não
  cria, não altera e não apaga nada nessa pasta; só o ssh grava nela, como
  faria no Windows (o `known_hosts`, por exemplo).
- A configuração fica em `%LOCALAPPDATA%\WinPlaybook\settings.json`, em lugar
  fixo, e só as funções de `Settings/` leem e gravam esse arquivo.
- Nos perfis do PowerShell (o `profile.ps1` do PowerShell 7 e o do Windows
  PowerShell, em Documentos), o WinPlaybook acrescenta só a linha do
  autocomplete, e a desinstalação a tira. Um perfil que fica vazio é apagado.
- A extensão Ansible do VS Code só muda pelo
  `Enable-WinPlaybookVSCodeExtension`, que guarda cada arquivo original ao
  lado dele, com `.winplaybook-original`. O WinPlaybook não altera as
  configurações do VS Code: a documentação diz o que o usuário põe no
  `settings.json`, porque ele pode ter perfis e configurações por projeto.
- A desinstalação desfaz toda alteração que o WinPlaybook fez no sistema,
  seja na instalação ou em qualquer outro comando, como a distribuição
  `WinPlaybook`, a pasta dos shims, a entrada no `PATH` do usuário e a
  configuração.
