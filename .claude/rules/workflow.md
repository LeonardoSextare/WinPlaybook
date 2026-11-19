---
description: Fluxo de uma tarefa, do pedido ao PR, e o limite da autonomia.
---

# Fluxo de trabalho

Toda tarefa segue as etapas abaixo, na ordem.

## Autonomia

- Dentro da branch da tarefa, você tem autonomia total: implementar, testar,
  commitar, reescrever o histórico, enviar e abrir o PR.
- O mantenedor revisa todo PR. O merge é dele, a não ser que ele peça para
  você completar o PR (etapa 10).
- A exceção é a stack: mudança ou adição de ferramenta ou dependência é
  discutida com o mantenedor antes de entrar no código.
- Uma tarefa por vez: ao abrir o PR, reporte o resultado e espere a próxima.
  Não emende outra tarefa por conta própria, mesmo que ela pareça óbvia. A
  exceção é uma fila que o mantenedor libera, como o roadmap: nela, ao abrir
  o PR de uma tarefa, siga para a próxima.

## Issues

- Issues, comentários e PRs são escritos em português, como o resto do
  projeto.
- Um bug ou comportamento inesperado encontrado durante uma tarefa vira uma
  issue, com o que se sabe dele, e entra no roadmap na posição em que se
  encaixa. A tarefa atual continua no escopo dela.

## 1. Entender o pedido

- Antes de mexer em qualquer arquivo, leia o código envolvido.
- Pare e pergunte quando o pedido for ambíguo e a escolha mudar o resultado.
  Para escolhas com um padrão claro, siga o padrão e diga qual escolheu.
- Se o pedido conflita com os padrões do projeto, aponte o conflito antes de
  começar.

## 2. Planejar

- Planeje os commits antes de começar: uma lista de mudanças lógicas, cada
  uma um commit.
- Se a tarefa não cabe num PR que se revisa de uma vez, divida em tarefas
  menores e proponha a ordem.

## 3. Criar a branch

- Nunca commite direto na `main`. Cada tarefa tem uma branch própria, criada a
  partir da `main` atualizada:

  ```powershell
  git switch main
  git pull --ff-only
  git switch -c <tipo>/<descricao>
  ```

- O nome da branch é o tipo do commit principal e uma descrição curta, em
  português, em kebab-case e sem acentos (`fix/caminhos-com-colchetes`).

## 4. Implementar

- Mantenha os padrões do projeto e do código ao redor.
- Escreva ou ajuste os testes junto com o código, no mesmo commit. Todo teste
  novo é visto falhando antes de passar.
- Atualize a documentação junto com o código, no mesmo commit e nos dois
  idiomas: toda mudança que o usuário percebe, como um parâmetro, uma mensagem,
  uma pergunta, um caminho ou um comportamento, muda também as páginas que falam
  dela, a ajuda do comando e o README, quando for o caso.
- Fique no escopo da tarefa. Anote no relatório final o que notar fora dele,
  como um bug ou um texto desatualizado, sem mexer no código.
- Commite a cada mudança lógica concluída.

## 5. Verificar

Antes de abrir o PR:

- Rode os testes das camadas afetadas no PowerShell 7 e no Windows
  PowerShell 5.1. Mudança em `module/` roda pelo menos `unit/` e o que mais
  tocar o comportamento alterado; mudança só em `docs/` não precisa de
  testes.
- Mudança em `docs/` passa pelo build dos dois idiomas e pela revisão de
  entrega da documentação.
- Procure na documentação (`docs/pt-br`, `docs/en` e os READMEs) e na ajuda
  dos comandos o que fala do comportamento alterado, como os nomes dos
  comandos, dos parâmetros e das mensagens, e confira que tudo descreve o
  comportamento novo.
- Revise o próprio diff com `git diff main...HEAD`, procurando sobras de
  depuração, arquivos que não deveriam estar ali e mudanças fora do escopo.

## 6. Organizar o histórico

- Para corrigir algo que um commit anterior da branch introduziu, use
  `git commit --fixup <hash>`, nunca um commit `fix` separado.
- Junte os fixups e traga a branch para a `main` atual:

  ```powershell
  git fetch origin
  git rebase --autosquash origin/main
  ```

- Confira com `git log --oneline origin/main..HEAD` que cada commit é uma
  mudança completa, com uma mensagem que faça sentido no changelog.
- Confira os títulos com `./scripts/Test-TituloDeCommit.ps1`, o mesmo check
  que o CI roda no PR.
- Depois de reescrever o histórico de uma branch já enviada, use
  `git push --force-with-lease`. Nunca use `--force`.

## 7. Abrir o PR

- Abra com `gh pr create`. O título resume o conjunto de commits, em
  português, e não entra no changelog.
- A descrição segue este modelo:

  ```markdown
  ## O que muda

  ## Por quê

  ## Como foi testado

  ## Pontos de atenção
  ```

  "Pontos de atenção" lista decisões que o mantenedor talvez queira rever, o
  que ficou de fora e o que foi notado fora do escopo. Sem pontos, a seção
  sai.
- Se a tarefa vem de uma issue, a descrição termina com `Closes #<número>`.

## 8. Acompanhar o CI

- Acompanhe os checks com `gh pr checks --watch`.
- Se um check falhar, leia o log, encontre a causa e corrija com um commit
  novo ou um fixup. Não rode o CI de novo esperando outro resultado sem
  entender a falha.
- Se a falha não tem relação com a mudança, ou se duas tentativas de correção
  não resolverem, pare e reporte ao mantenedor.

## 9. Reportar

Ao abrir o PR, ou ao parar numa etapa que espera o mantenedor, informe:

- o que foi feito e o link do PR;
- as decisões tomadas sem consulta e o motivo;
- o que ficou pendente e o que foi notado fora do escopo.

## 10. Completar o PR

Só quando o mantenedor pede, como em "pode completar o PR".

- Confira que todos os checks passaram e que o PR não tem conflito.
- Faça o merge pelo próprio PR, por rebase, que é o único método que a `main`
  aceita:

  ```powershell
  gh pr merge <número> --rebase
  ```

- Traga a `main` local para o estado novo:

  ```powershell
  git switch main
  git pull --ff-only
  ```

- Confirme com `git log --oneline` que os commits do PR chegaram à `main` e
  reporte ao mantenedor.

## Nunca

- Commitar ou reescrever a `main`.
- Fazer o merge de um PR sem o pedido do mantenedor, ou fora do PR, com push
  direto na `main`.
- Pular, desativar ou enfraquecer testes, checks ou hooks para o CI passar
  (`--no-verify`, `-Skip`, apagar asserções).
- Alterar workflows do CI para contornar uma falha.
- Criar tags e releases ou publicar o módulo à mão, que são tarefas do CI.
