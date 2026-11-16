---
paths:
  - "tests/**"
---

# Testes

Pester 6 em todas as camadas. Abordagens novas do Pester são discutidas com o
mantenedor antes de virar padrão.

## O que testar

- Toda função do módulo tem teste unitário, inclusive as privadas: evita
  regressão silenciosa em funções que só a API pública usaria.
- Teste o comportamento, não a implementação: o que o módulo e o usuário
  percebem. Mudar a forma de montar a chamada ao `wsl.exe` sem mudar o comando
  que roda na distribuição não deve quebrar nenhum teste.
- Unit e integration não usam a internet. Nos e2e, ela entra só quando o
  comportamento testado depende dela.
- Todo teste novo precisa ser visto falhando ao menos uma vez (valor errado,
  comando inexistente), para provar que ele detecta o problema.

## Organização

- Uma pasta por camada, cada uma com o próprio job no CI (`module.yml`):
  - `tests/unit/`: funções do módulo. Efeitos colaterais só em recursos
    descartáveis que o teste cria e apaga (`$TestDrive`, variáveis
    `WINPLAYBOOK_TEST_`); o resto (o `wsl.exe`, o `Path` real) via `Mock`.
    Espelha as pastas do módulo: `unit/Public/` e `unit/Private/<assunto>/`,
    para o teste de cada função ficar no mesmo caminho dela
  - `tests/integration/`: o `shim.exe` empacotado, executado de verdade
  - `tests/e2e/`: o módulo e uma distribuição WSL de verdade, como o usuário
    usa
- `tests/helpers/<Assunto>.ps1`: funções reutilizáveis, carregadas com
  dot-sourcing dentro do `BeforeAll`. Extraia um helper quando a repetição
  aparecer, não antes.
- `tests/data/projects/<cenario>/`: um projeto Ansible por cenário, em
  kebab-case, contendo só o necessário para aquele cenário. Testes copiam o
  projeto para o `$TestDrive`; nunca alteram a pasta `data/`.

## Escrita

- Arquivo `<Assunto>.Tests.ps1` em PascalCase; para teste unitário, o assunto é
  o nome da função.
- Cada arquivo é autossuficiente: a preparação fica no `BeforeAll` do próprio
  arquivo (inclusive `Initialize-DistribuicaoWslDeTeste`, que reaproveita a
  distribuição já preparada).
- Nada solto fora dos blocos: preparação em `BeforeAll`, dados que geram testes
  em `BeforeDiscovery`.
- Nomes em português formando frase: `Describe` = assunto, `Context` =
  condição (`quando ...`), `It` = verbo no presente (`propaga ...`, não
  `deve propagar ...`). Nomes de comandos, funções e parâmetros aparecem como
  estão no código (`Describe 'Invoke-WinPlaybook'`).
- `Context` agrupa testes que compartilham uma condição e a preparação dela.
- Arrange / Act / Assert separados por linha em branco, sem comentários de seção.
- Um comportamento por `It`; sem `if`/`foreach` no corpo. Variações via
  `-ForEach` (`<_>` para listas simples, `<Chave>` para hashtables).
- Asserções na sintaxe nova (`Should-Be`, `Should-BeLikeString`...), nunca a
  clássica (`Should -Be`).
- Asserção sobre processo externo leva diagnóstico: `-Because $output`.
- Testes independentes entre si e da ordem de execução.
- Recurso criado em `BeforeAll` é removido em `AfterAll`.
- Caminhos relativos montados com `Join-Path` e escritos com `/`
  (`Join-Path $PSScriptRoot '../helpers/Wsl.ps1'`).
- Sem comentários explicando o teste.

## WSL nos testes

- Chamadas diretas ao `wsl.exe` passam pelo `Invoke-Wsl` de
  `tests/helpers/Wsl.ps1`, que captura código de saída e saída sem quebrar no
  Windows PowerShell 5.1.

## Shim nos testes

- Usam o `module/WinPlaybook/bin/shim.exe` baixado por `scripts/Save-Shim.ps1`
  (o `setup.ps1` chama); o teste não baixa nada.
- Chamam o `.exe` como um programa externo, com `Invoke-LinhaDeComando` de
  `tests/helpers/Processo.ps1` (linha de comando em texto bruto via
  `Start-Process`), nunca `&`, que no 5.1 altera aspas antes de chegar ao shim.

## Variáveis de ambiente nos testes

- Nunca no `Path` real: as funções recebem `-NomeDaVariavel`, e o teste usa
  uma variável descartável `WINPLAYBOOK_TEST_<guid>` (helpers de
  `tests/helpers/Ambiente.ps1`).
- `Clear-VariavelDeTeste` no `BeforeAll` e no `AfterAll` apaga as sobras de
  execuções interrompidas; `Remove-VariavelDeTeste` no `AfterEach` apaga a do
  teste.
- O `Path` real só é alterado em máquina descartável (CI, Windows Sandbox).

## Testes unitários do módulo

- O módulo é importado pelo manifesto no `BeforeAll`, com o caminho relativo
  à pasta do teste
  (`Import-Module (Join-Path $PSScriptRoot '../../../../module/WinPlaybook/WinPlaybook.psd1') -Force`
  em `unit/Private/<assunto>/`) e removido no `AfterAll`
  (`Remove-Module WinPlaybook`).
- Funções privadas são chamadas com `InModuleScope WinPlaybook`; os valores
  do caso entram por `-Parameters` (`-Parameters $_` com `-ForEach`).
- Mocks de algo que o módulo chama (inclusive o executável `wsl`) levam
  `-ModuleName WinPlaybook`. `Mock wsl -ModuleName WinPlaybook { $args }`
  devolve os argumentos montados sem chamar o WSL.
- Um teste que confere o texto de uma mensagem fixa o português com
  `Mock Get-CulturaDaInterface -ModuleName WinPlaybook { 'pt-BR' }`, para
  passar em qualquer idioma do Windows. Nos e2e, que não usam mocks, o texto
  esperado vem do `Get-Mensagem`.

## Testes e2e

- Usam uma distro WSL só de testes, nunca as do desenvolvedor:
  `Initialize-DistribuicaoWslDeTeste` (`tests/helpers/Wsl.ps1`) no `BeforeAll`
  cria ou reaproveita a `WinPlaybookTest` e devolve o nome. No CI, a action
  `Vampire/setup-wsl` instala a distro, e a variável
  `WINPLAYBOOK_TEST_WSL_DISTRIBUTION` do job passa o nome dela à action e aos
  testes. A preparação instala o `uv`, o `ansible-core` e o `ansible-lint` na
  primeira vez, com internet; os testes em si não usam internet.
- Usam uma configuração no `$TestDrive`: o teste troca o `$env:LOCALAPPDATA`
  por uma pasta no `$TestDrive`, grava ali a distro de testes com
  `Save-Configuracao` e restaura o valor original no `AfterAll`. Sem isso, o teste
  leria e alteraria a configuração do desenvolvedor.
- Chamam o módulo como o usuário, a partir de uma cópia do projeto no
  `$TestDrive` (`Push-Location`/`Pop-Location`), e verificam saída e
  `$LASTEXITCODE`.
- Shims são gerados no `$TestDrive` (nunca com `Install-WinPlaybookShim`, que
  mexe no `Path` real), com `-PastaDoModulo (Get-PastaDoModulo)`. Eles
  carregam o módulo do repositório pela pasta dele, sem mudar o
  `$env:PSModulePath`, como o usuário que instalou o módulo para uma edição só.
- Argumentos com aspas, como JSON, são testados de ponta a ponta: só o
  `wsl.exe` real mostra o que o PowerShell 5.1 faz com eles.

## Comparação com o Ansible nativo

- O `e2e/ComportamentoNativo.Tests.ps1` confere que o WinPlaybook entrega o
  mesmo que o Ansible instalado no Linux. Cada cenário roda direto na distro
  de testes, com o projeto copiado para o disco do Linux, e pelos shims,
  chamados pelo PowerShell e por outro programa.
- O teste compara o código de saída, a saída, os erros e os arquivos que
  ficam no projeto, com a pasta do projeto trocada por `<projeto>`. O Ansible
  é o mesmo dos dois lados, então qualquer diferença vem do WinPlaybook.
- O lado nativo usa o `tests/helpers/AnsibleNativo.ps1`: a cópia para o disco
  do Linux tem as permissões de um projeto criado lá, e o comando roda num
  login shell, sem que um shell interprete os argumentos.
- Um comportamento do Ansible que o WinPlaybook passa a reproduzir entra como
  cenário nesse arquivo, no mesmo commit da mudança.

## Execução

- `Invoke-Pester -Path tests/<camada> -Output Detailed`, ou `tests` para todas
  as camadas.
- Rodar nas duas edições: PowerShell 7 e Windows PowerShell 5.1.
- No CI, os testes unitários rodam no código e no pacote publicado, e os e2e
  só no pacote, que é o que o usuário recebe. Para isso, o job troca o
  `module/WinPlaybook` pelo pacote do `scripts/Build-PacoteDoModulo.ps1`. Um
  teste que depende de um arquivo do módulo além do manifesto, dos
  `Mensagens.psd1` e do `bin\shim.exe` quebra no pacote.
