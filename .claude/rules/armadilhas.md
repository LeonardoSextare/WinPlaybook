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
- No `/etc/fstab`, uma `\` seguida de três dígitos vira o caractere desse
  código octal, e o espaço separa os campos. Um caminho do Windows como
  `C:\Temp\714b` chega ao `mount` como lixo. O
  `Initialize-DistribuicaoDoWinPlaybook` escreve a `\` como `\134` e o espaço
  como `\040` na pasta .ssh que monta.
- Quando uma pasta do Windows do `/etc/fstab` não existe, o WSL escreve
  `Processing /etc/fstab with mount -a failed` no stderr do primeiro comando
  depois do boot. O `Initialize-DistribuicaoDoWinPlaybook` só põe a pasta
  .ssh no `/etc/fstab` quando ela existe.

- Todas as distribuições WSL 2 rodam na mesma VM, e o `systemd-binfmt` de uma
  distribuição com systemd, como o Ubuntu, apaga o registro `WSLInterop` do
  `binfmt_misc` da VM inteira. Sem ele, a distribuição não executa programas
  do Windows (`Exec format error`), e a ponte de rede, o agente SSH e os
  programas do `Path` param. Antes de cada comando, o `Invoke-ComandoNoWsl`
  chama o `Repair-InteropDoWsl`, que confere o registro pelo `\\wsl.localhost`
  e só o refaz como root quando ele falta. O teste "executa programas do
  Windows depois que outra distribuição apaga o registro do interop" do
  `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` confere.

## Unidades e pastas de rede

- O WSL monta só as unidades fixas. Uma unidade do `subst`, uma unidade de
  rede mapeada ou uma pasta UNC (`\\servidor\compartilhamento`) não existe na
  distribuição, e o `wsl --cd` com uma delas escreve
  `wsl: Failed to translate` e começa na pasta pessoal, sem falhar. O
  `Invoke-ComandoNoWsl` troca a unidade pela pasta real que o
  `Get-DestinoDeUnidade` informa e monta os compartilhamentos de rede com o
  `Mount-PastaDoWindows`. A montagem fica por compartilhamento, e não por
  letra, porque uma letra pode apontar para outra pasta depois, e a montagem
  antiga continuaria lá até a distribuição parar. O
  `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` roda um playbook das três.
- Um programa externo que o módulo chama herda a entrada padrão do shim e pode
  consumir o que chegaria ao Ansible, como o texto cifrado de um
  `ansible-vault decrypt` chamado por outro programa. O
  `Get-DestinoDeUnidade` chama o `subst.exe` com `$null |`, que dá a ele uma
  entrada vazia. Os cenários com entrada padrão do
  `ComportamentoNativo.Tests.ps1` conferem.

## Processos na distribuição

- A linha de comando de um processo do Windows tem no máximo 32.767
  caracteres. Passar o código do supervisor e o JSON das variáveis como
  argumentos do `wsl.exe` estourou o limite num ambiente com muitas variáveis
  (`The filename or extension is too long`). O `Invoke-ComandoNoWsl` passa o
  caminho do arquivo que o `Get-CaminhoDoSupervisor` grava na pasta
  temporária e o JSON na variável `WINPLAYBOOK_ENVIRONMENT`, pelo `WSLENV`. O
  teste unitário "mantém a linha de comando curta com um ambiente grande"
  confere.

- Quando o processo do Windows que chamou o `wsl.exe` termina, como num
  terminal fechado ou num comando que o VS Code cancela, o WSL manda SIGHUP
  para a sessão do comando. Os workers do Ansible abrem uma sessão própria e
  não recebem o sinal, e o playbook continua rodando sem ninguém. O
  `Invoke-ComandoNoWsl` executa o comando pelo supervisor de
  `Get-ScriptDoSupervisor`, que adota os processos órfãos (subreaper) e
  encerra todos quando recebe SIGHUP ou SIGTERM. O
  `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` mata o processo do Windows
  no meio de uma tarefa e confere que nada sobra na distribuição.
- Num `sh` não interativo, um comando em segundo plano (`&`) recebe o
  `/dev/null` como entrada antes das outras redireções, e um `0<&0` só repete
  o `/dev/null`. O script do `Invoke-ComandoNoWsl` guarda a entrada no
  descritor 3 (`exec 3<&0`) antes e a devolve ao comando com `0<&3 3<&-`. Os
  cenários com entrada padrão do `ComportamentoNativo.Tests.ps1` conferem.
- O WSL entrega a entrada padrão redirecionada do Windows como um pipe do root
  com modo 600. O usuário `winplaybook` lê o descritor 0, mas não consegue
  reabri-lo pelo `/dev/stdin` (`Permission denied`). Quando a entrada não é
  um terminal, o supervisor de `Get-ScriptDoSupervisor` a repassa ao comando
  por um pipe do próprio usuário. O cenário do `/dev/stdin` do
  `ComportamentoNativo.Tests.ps1` confere, e o lado nativo do teste lê a
  entrada com `cat arquivo |`, porque o mesmo pipe do root quebraria o
  `/dev/stdin` dele também.
- Um programa do Windows que um processo da distribuição abre pelo interop só
  troca dados com a distribuição enquanto a sessão do `wsl.exe` que o abriu
  existe. Um daemon que sobrevive à sessão continua rodando, mas a saída do
  programa do Windows para de chegar a ele. Por isso a ponte para o
  `localhost` do Windows roda dentro do supervisor de cada comando, e não num
  serviço da distribuição, e a regra do nftables é aplicada pelo
  `/usr/local/lib/winplaybook/nft`, que o usuário `winplaybook` executa com a
  CAP_NET_ADMIN. Os testes "quando um serviço escuta no localhost do Windows"
  do `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` conferem.

## Ansible

- A detecção de interpretador do Ansible, num host com conexão local, procura
  `python3.14`, `python3.13` e os outros nomes no `PATH` e fica com o mais
  novo. Com o `Path` do Windows no `PATH`, ela escolheria um Python do
  Windows, como os aliases da Microsoft Store, e o módulo falharia com
  `Module result deserialization failed`. O supervisor de
  `Get-ScriptDoSupervisor` não cria o nome sem extensão do Python e do pip, e
  o `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` confere que a detecção
  escolhe o `/usr/bin/python3`.

- Numa função avançada, o `-i` do Ansible vira um parâmetro ambíguo do
  PowerShell. A função que repassa argumentos ao Ansible é simples, sem
  `[CmdletBinding()]` nem `param()`, e usa `$args`.
- Por padrão, o WSL monta as unidades do Windows com permissão 777. O Ansible
  ignora o `ansible.cfg` de uma pasta com escrita para todos, executa como
  script o arquivo de `--vault-password-file` e o SSH recusa a chave. O
  `Initialize-DistribuicaoDoWinPlaybook` grava no `/etc/wsl.conf` da
  distribuição a montagem com `metadata,umask=22,fmask=111` (pastas 755 e
  arquivos 644), e o `ComportamentoNativo.Tests.ps1` confere o `ansible.cfg` e
  o vault.
- O `ansible-core` declara só a versão mínima do Python, e o `uv` escolhe o
  Python mais novo, em que o Ansible pode quebrar ao importar (como o
  `ansible-core` 2.21 no Python 3.15). O `Install-AnsibleNaDistribuicao` tenta
  do Python mais novo para o mais antigo e fica com o primeiro em que o
  `ansible --version` funciona.

## Shims

- Aberto com `-File`, o PowerShell interpreta os argumentos do script que
  começam com `-`. O PowerShell 7 separa `--inventory=C:\hosts.yml` em
  `--inventory=C` e `\hosts.yml`, as duas edições separam `-i:valor`, e o 5.1
  recusa um argumento que é só `-` (`ansible-vault decrypt --output - -`)
  antes de o script rodar, mesmo depois de um `--`. O executável dos shims
  (`Shim.cs`) passa cada argumento como `x` seguido do texto em Base64, que o
  `-File` não interpreta, e o `exe\<comando>.ps1` decodifica. O
  `tests/module/integration/Shim.Tests.ps1` confere esses argumentos nas duas
  edições.
- Chamado pelo `.exe` com `-File`, o PowerShell sai com 0 mesmo quando o
  comando falha. O `.ps1` gerado para cada shim termina com
  `exit $LASTEXITCODE`.
- Cada edição do PowerShell procura os módulos nas próprias pastas
  (`Documents\WindowsPowerShell\Modules` no 5.1 e `Documents\PowerShell\Modules`
  no 7), e um shim que chama o módulo pelo nome falha na outra edição. Os
  scripts dos shims importam o módulo pela pasta sem a versão
  (`Get-PastaDoModulo`), e o `Import-Module` carrega a versão mais nova dela.
- Aberto com `-File` e com a entrada padrão redirecionada, o PowerShell lê a
  entrada para o `$input` do script quando ele cita `$input`, mesmo num trecho
  que não roda, e o programa que o script chama recebe a entrada vazia. O
  `.exe` abre o `exe\<comando>.ps1`, que não cita `$input`. Só o `.ps1` que o
  PowerShell executa repassa o pipeline.
- O PowerShell escreve cada linha do pipeline na entrada de um programa com
  `\r\n`, e o 5.1 pode pôr um BOM no começo, mesmo com o `$OutputEncoding` em
  UTF-8 sem BOM. O `Invoke-ComandoNoWsl` manda o pipeline em UTF-8, e o script
  na distribuição tira o BOM e os `\r` com o `sed`.

## Agente SSH

- Num handle de named pipe aberto em modo síncrono, o Windows serializa as
  operações: uma leitura pendente bloqueia a escrita no mesmo handle. O relay
  do agente SSH lê o pipe numa thread e escreve em outra, e com um handle
  síncrono ele trava ou quebra o pipe, conforme o servidor. O
  `RelayDoAgenteSsh.cs` abre o pipe com `PipeOptions.Asynchronous`, e o
  `tests/module/integration/RelayDoAgenteSsh.Tests.ps1` confere a ida e a
  volta de um pedido nas duas edições.

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

## Variáveis de ambiente

- No PowerShell 7, o `[Environment]::SetEnvironmentVariable($nome, $null)`
  deixa a variável definida com valor vazio, porque o PowerShell passa uma
  string vazia para o .NET. No 5.1, a variável some. Para apagar uma variável,
  use `Remove-Item -LiteralPath "Env:$nome"`. Um `ANSIBLE_` vazio muda o
  Ansible, que lê um booleano vazio como falso.

## Arquivos do módulo

- O `$PSScriptRoot` de uma função depende do arquivo onde ela está, e o pacote
  publicado junta as funções num `.psm1` só. Para achar um arquivo do módulo,
  como o `Shim.cs`, parta da pasta do módulo
  (`$ExecutionContext.SessionState.Module.ModuleBase`), nunca do
  `$PSScriptRoot`.

## Rede

- Um `redirect` do nftables entrega a conexão a um listener local, e o kernel
  completa o handshake antes de o destino real responder. Uma porta recusada
  no destino viraria uma conexão que abre e fecha sem erro. Quando o relay de
  rede falha ao conectar, o supervisor de `Get-ScriptDoSupervisor` fecha a
  conexão com RST (`SO_LINGER` 0), e o cliente vê `Connection reset by peer`.
  O teste "interrompe a conexão quando o destino fora do localhost a recusa"
  do `tests/module/e2e/Invoke-WinPlaybook.Tests.ps1` confere.
- No Python, fechar um socket enquanto outra thread está bloqueada no `recv`
  dele não envia nada ao outro lado. Para mandar o RST, o supervisor chama
  `shutdown(SHUT_RD)`, que libera o `recv`, e o socket fecha quando a thread
  que o lê termina.
- As regras do nftables ficam na distribuição depois que o processo que as
  aplicou termina. Com a regra que leva todo o TCP para a porta da ponte, um
  comando sem ninguém escutando nela ficaria sem rede. O dono da ponte apaga a
  tabela ao sair, e um supervisor que não liga a ponte apaga a tabela que
  ficou sem dono, como a de um comando encerrado à força. O teste "deixa a
  rede da distribuição como estava quando o comando termina" confere.
- Só um supervisor é dono da porta da ponte, e um programa do Windows aberto pelo
  interop só troca dados enquanto a sessão do `wsl.exe` que o abriu existe.
  Se o dono atendesse as conexões de todos, elas morreriam quando o comando dele
  terminasse. O dono acha, pelo `/proc`, o supervisor do processo que abriu a
  conexão e entrega o socket a ele pelo canal `@winplaybook-ponte-<pid>`
  (`SCM_RIGHTS`), e esse supervisor abre o relay pela própria sessão. Ao sair,
  o dono entrega os sockets de escuta a outro supervisor vivo. O teste "mantém a
  conexão aberta e abre novas depois que a outra execução termina" confere.

## Pester

- No Windows PowerShell 5.1, um processo que abre mais de um `relay-de-rede.exe`
  com o `Diagnostics.Process` e a entrada e as saídas redirecionadas para pipes às
  vezes não recebe a saída do segundo, e a leitura trava para sempre. No uso real,
  quem abre o relay é a distribuição. O `tests/module/integration/RelayDeRede.Tests.ps1`
  abre cada relay com o `Start-Process` e a entrada e as saídas em arquivos.
- O Pester faz mock de funções, não de métodos do .NET. Uma chamada a método
  estático que os testes precisam simular fica numa função privada própria.
