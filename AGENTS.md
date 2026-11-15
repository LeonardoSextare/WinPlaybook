# WinPlaybook

O WinPlaybook permite usar o Ansible no Windows como se ele estivesse
instalado localmente. O Ansible não roda nativamente no Windows, então o
WinPlaybook o executa numa distribuição WSL e coloca o `ansible-playbook`, o
`ansible-lint` e os demais comandos do Ansible no `PATH` do Windows. Assim o
terminal, os scripts e ferramentas como a extensão Ansible do VS Code chamam
esses comandos sem saber que eles rodam no Linux. Para mais detalhes, veja
[Por que o WinPlaybook](docs/pt-br/why-winplaybook.md).

O WinPlaybook é um módulo PowerShell, distribuído pela PowerShell Gallery e
compatível com o Windows PowerShell 5.1 e o PowerShell 7. A distribuição WSL
pode ser uma que o usuário já tem ou uma que o WinPlaybook prepara; como essa
preparação vai funcionar ainda está em definição.

O projeto está na versão 0: já tem releases iniciais, mas ainda não é
estável, e qualquer release pode trazer breaking changes.

### Um repositório em transição

O projeto está mudando as regras do próprio repositório, como o código que
está sendo traduzido para o português. Este arquivo descreve o projeto como
ele deve ser, então partes dele ainda não estão aplicadas, e os arquivos do
repositório podem divergir do que está escrito aqui. Quando houver
divergência, este arquivo mostra para onde o projeto está indo, e o código
mostra onde ele está hoje.

Enquanto a transição não termina, a publicação de releases está pausada.

Esta seção é um aviso temporário: quando a transição terminar, ela é removida
por inteiro.

## Stack

O projeto usa as ferramentas abaixo. Qualquer mudança ou adição na stack é
discutida antes de entrar no projeto.

| Item               | Uso                         | Versão                                   |
| ------------------ | --------------------------- | ---------------------------------------- |
| Windows            | Sistema operacional         | 10 ou 11                                 |
| PowerShell         | Módulo e scripts            | 7.4 ou mais recente                      |
| Windows PowerShell | Módulo                      | 5.1                                      |
| WSL                | Execução do Ansible         | Mais recente                             |
| Pester             | Testes                      | 6                                        |
| Zensical           | Site de documentação        | Mais recente                             |
| uv                 | Execução do Zensical        | 0.11.14 ou mais recente                  |
| git                | Controle de versão          | Mais recente                             |
| git-cliff          | Versões e notas de release  | Mais recente                             |
| GitHub Actions     | CI e releases               | Runners `windows-2025` e `ubuntu-latest` |
| Renovate           | Atualização de dependências | Mais recente                             |

## Estrutura do repositório

| Caminho                | Conteúdo                                                                      |
| ---------------------- | ----------------------------------------------------------------------------- |
| `module/WinPlaybook/`  | O módulo publicado: manifesto, `.psm1` e as funções em `Public/` e `Private/` |
| `module/shim.psd1`     | A versão e o hash do `shim.exe` empacotado com o módulo                       |
| `tests/`               | Os testes do módulo, separados por camada                                     |
| `scripts/`             | Scripts do CI e do release, como baixar o `shim.exe` e montar o pacote        |
| `scripts/dev/`         | Scripts de desenvolvimento: preparação do ambiente e preview da documentação  |
| `docs/`                | O site de documentação, em português e inglês                                 |
| `.github/`             | Os workflows do CI e as actions locais                                        |
| `.claude/`             | Instruções específicas para o Claude Code                                     |
| `requirements.psd1`    | Os módulos PowerShell usados no desenvolvimento, como o Pester                |
| `cliff.toml`           | A configuração do git-cliff, que gera versões e notas de release              |
| `renovate.json`        | A configuração do Renovate, que atualiza as dependências                      |

## Ambiente de desenvolvimento

A task "Preparar o ambiente" do VS Code, ou o `scripts/dev/setup.ps1`, confere os
requisitos e instala as dependências do desenvolvimento local.

## Comandos

Os comandos rodam na raiz do repositório, no PowerShell 7.

| Para                                            | Comando                                                                                |
| ----------------------------------------------- | -------------------------------------------------------------------------------------- |
| Preparar o ambiente local                       | `./scripts/dev/setup.ps1`                                                              |
| Rodar uma camada de testes                      | `Invoke-Pester -Path tests/<camada> -Output Detailed`                                  |
| Rodar todos os testes                           | `Invoke-Pester -Path tests -Output Detailed`                                           |
| Rodar os testes no Windows PowerShell 5.1       | `powershell -NoProfile -Command "Invoke-Pester -Path tests/<camada> -Output Detailed"` |
| Conferir os títulos dos commits da branch       | `./scripts/Test-TituloDeCommit.ps1`                                                    |
| Ver a documentação de um idioma, com hot reload | `uvx zensical serve -f docs/zensical.pt-br.toml`                                       |
| Ver o site completo, com o seletor de idioma    | `./scripts/dev/docs.ps1`                                                               |

## Convenções de código

- **Idioma:** o código é escrito em português, com os termos técnicos em
  inglês quando esse é o uso comum.
- **Nomenclatura:** os nomes são claros, descritivos e diretos. As funções
  seguem as convenções do PowerShell, como os verbos aprovados.
- **Comentários:** o código não tem comentários. Os nomes e a estrutura dizem
  o que ele faz.
- **Simplicidade e qualidade:** o código resolve o caso que existe hoje, sem
  abstrações ou opções para casos hipotéticos, e é fácil de ler e de mudar.
- **Compatibilidade:** o módulo roda no Windows PowerShell 5.1 e no
  PowerShell 7, e cada mudança funciona e é testada nas duas edições.
- **Dependências:** o módulo depende só do Windows e do WSL, sem outros
  módulos PowerShell. Qualquer dependência nova é discutida antes de entrar.
- **Arquitetura:** cada função fica num arquivo próprio. `Public/` tem os
  comandos do usuário, e `Private/` as funções internas, organizadas por
  assunto. O módulo é publicado como está, sem etapa de build.
- **Sistema do usuário:** o WinPlaybook altera o mínimo possível no sistema e
  pode ser removido por completo com facilidade. Um comando que falha não
  deixa nada pela metade.
- **Erros que orientam:** as mensagens de erro dizem o que aconteceu e o que
  o usuário pode fazer.

As regras detalhadas estão em [.claude/rules/code.md](.claude/rules/code.md).

As armadilhas ficam em [.claude/rules/armadilhas.md](.claude/rules/armadilhas.md).
São comportamentos do PowerShell, do Windows e das ferramentas que já causaram
bugs. Cada uma vem com a forma de evitá-la e com um teste que impede que ela
volte.

## Testes

Os testes usam o Pester 6 e ficam em `tests/`, em três camadas, que diferem
no quanto do sistema real participa do teste.

- `unit/`: só o código do WinPlaybook. Tudo o que está fora da função
  testada é mockado, então os testes são rápidos e não tocam o sistema. Cada
  função do módulo tem teste unitário, inclusive as privadas.
- `integration/`: o código do WinPlaybook com outros sistemas de verdade,
  como o sistema operacional, o sistema de arquivos ou o `shim.exe`. Os mocks
  ficam só para sistemas externos que são caros de testar.
- `e2e/`: o sistema completo, de ponta a ponta, como o usuário usaria de
  verdade. Nada é mockado, e é aqui que ficam os testes caros. Eles rodam
  numa distribuição WSL só de testes, para não mexer nas do desenvolvedor.

Duas pastas dão apoio às camadas:

- `helpers/`: funções reutilizáveis entre arquivos de teste, separadas por
  assunto.
- `data/`: os dados que os testes usam, como projetos Ansible prontos para
  cada cenário.

Princípios que valem para todas as camadas:

- **Comportamento:** os testes verificam o que o código
  entrega, não como ele faz. Uma refatoração que mantém o comportamento não
  quebra nenhum teste.
- **Independência:** cada teste roda sozinho, em qualquer ordem, e limpa o
  que cria.
- **Internet só quando inevitável:** unit e integration não usam a internet.
  Nos e2e, ela entra só quando o comportamento testado depende dela.

O CI roda as três camadas no PowerShell 7 e no Windows PowerShell 5.1, em
runners Windows. Os comandos para rodar os testes localmente estão em
[Comandos](#comandos), e as regras detalhadas, em
[.claude/rules/tests.md](.claude/rules/tests.md).

## Documentação

O site de documentação é feito para quem usa o WinPlaybook; assuntos de
desenvolvimento ficam neste arquivo e nas rules. Ele é gerado pelo Zensical e
publicado no GitHub Pages a cada push na `main` que altera `docs/`.

- **Páginas:** seguem o modelo [Diátaxis](https://diataxis.fr/). Cada uma é
  um tutorial, um guia, uma referência ou uma explicação.
- **Homepage:** apresenta o WinPlaybook, com layout próprio em
  `docs/overrides/`. Os textos dela ficam no `index.md` de cada idioma.
- **Idiomas:** o português (`docs/pt-br/`) é a fonte, e o inglês
  (`docs/en/`) é traduzido e localizado a partir dele. Os dois têm sempre o
  mesmo conteúdo e mudam juntos.

Os comandos de preview estão em [Comandos](#comandos), e as regras
detalhadas, em [.claude/rules/docs.md](.claude/rules/docs.md).

## Commits e histórico

Os commits seguem o [Conventional Commits](https://www.conventionalcommits.org/),
e o git-cliff gera as versões e as notas de release a partir deles.
Particularidades do projeto:

- **Tipos:** `feat`, `fix`, `perf`, `refactor`, `docs`, `style`, `test`,
  `build`, `ci`, `chore` e `revert`, com `!` depois do tipo numa breaking
  change (`feat!: ...`).
- **Sem escopo:** `fix: ...`, nunca `fix(shim): ...`.
- **Descrição em português:** começa com um verbo no presente e em
  minúscula, sem ponto final e com até 72 caracteres, como em
  `fix: aceita caminhos com colchetes no Install-WinPlaybookShim`.
- **Corpo opcional:** explica o porquê quando ele não é óbvio pelo título. Ele
  fica no histórico, mas não entra no changelog.
- **Changelog:** entram só `feat`, `fix`, `perf` e `refactor`. Os outros tipos
  ficam apenas no histórico.
- **Um commit por mudança:** cada commit é completo e passa nos testes. Se o
  título precisa de um "e", são dois commits.
- **Rebase merge:** os PRs entram na `main` sem squash e sem commit de merge,
  então todo commit do PR chega à `main`. Correções de algo que o próprio PR
  introduziu, como um typo num commit anterior, são fundidas a esse commit
  antes do merge, e não viram um commit `fix` separado.
- **Conferência no CI:** o check "Commit titles" roda o
  `scripts/Test-TituloDeCommit.ps1` em todo PR e recusa título fora do
  formato, com escopo, com tipo desconhecido ou com descrição que começa com
  maiúscula, termina com ponto ou passa de 72 caracteres. Um commit fora da
  convenção sumiria do changelog sem aviso.

## Versionamento e releases

O WinPlaybook segue o SemVer. A versão não fica no repositório, onde o
manifesto guarda `0.0.0`: a fonte é a tag `v<versão>` do último release.

A cada push na `main`, o CI roda os testes e o git-cliff calcula a próxima
versão a partir dos commits desde a última tag. `feat` gera MINOR, e `fix`,
`perf` e `refactor` geram PATCH. Assim, uma refatoração ganha uma versão
própria, e um bug que ela trouxer aponta para essa versão. Enquanto o projeto
está abaixo da 1.0.0, uma breaking change também gera MINOR.

Quando há versão nova, o release publica o módulo na PowerShell Gallery e cria
o release no GitHub, com as notas geradas pelo git-cliff, em português.
