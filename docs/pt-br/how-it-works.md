# Como o WinPlaybook funciona

O WinPlaybook roda o Ansible numa distribuição WSL própria e coloca os
comandos dele no `PATH` do Windows. Esta página mostra as peças e o caminho de
um comando, da instalação até a execução. Para entender por que ele foi feito
assim, veja [Por que o WinPlaybook](why-winplaybook.md).

```mermaid
flowchart LR
    command("ansible-playbook") --> shim("Shim") --> module("WinPlaybook") --> distro("Distribuição WSL")
```

## Componentes

- **Módulo PowerShell**: o módulo `WinPlaybook`, da PowerShell Gallery. Na
  instalação, prepara a distribuição e cria os comandos. Depois, leva cada
  execução para a distribuição, pelo `Invoke-WinPlaybook`, que também executa
  qualquer outro comando dela.
- **Distribuição WSL**: a `WinPlaybook`, com o Debian, criada pelo
  `Install-WinPlaybook`. Tem o Ansible, o `ansible-lint` e o `pywinrm`, para
  gerenciar máquinas Windows. As distribuições que você já tem não são usadas.
- ***Shims***: um para cada comando do Ansible. Recebem a chamada do Windows e
  a passam para o módulo.

## A distribuição

O `Install-WinPlaybook` cria a distribuição com o Debian do catálogo do WSL,
com o disco em `C:\Users\<usuário>\AppData\Local\WinPlaybook\distro`, e a
prepara para o Ansible:

- instala o Python, o git, o ssh, o `sshpass` e o `rsync`, que o
  `ansible.posix.synchronize` usa;
- cria o usuário `winplaybook`, que executa os comandos;
- instala o Ansible com o [uv](https://docs.astral.sh/uv/), em
  `/home/winplaybook/.local/bin`, no Python mais novo em que ele funciona;
- monta as unidades do Windows com pastas `755` e arquivos `644`, como num
  disco do Linux. Assim o Ansible lê o `ansible.cfg` do projeto, que ele
  ignora numa pasta em que todos podem escrever;
- deixa o `Path` do Windows fora do `PATH` da distribuição, para que ela não
  execute os _shims_ do próprio WinPlaybook nem um programa do Windows com o
  mesmo nome de um comando do Linux.

As _collections_ e as _roles_ que o `ansible-galaxy` instala ficam em
`/home/winplaybook/.ansible`, no disco da distribuição, e continuam lá entre
uma execução e outra. No Windows, essa pasta aparece em
`\\wsl.localhost\WinPlaybook\home\winplaybook\.ansible`.

Executar o `Install-WinPlaybook` de novo mantém a distribuição e o que há
nela, como as _collections_, e reinstala o Ansible e os _shims_.

## Shims

Um _shim_ é um executável que repassa a chamada para outro programa. Os
_shims_ do WinPlaybook ficam em
`C:\Users\<usuário>\AppData\Local\WinPlaybook\bin`, no `PATH` do usuário. O
`Install-WinPlaybook` cria um para cada comando do Ansible que encontra na
distribuição.

O caminho até o módulo depende de quem chama o comando. O PowerShell executa
o `.ps1` direto; os outros programas passam pelo `.exe`:

```mermaid
flowchart LR
    pwsh("PowerShell") --> ps1("ansible-playbook.ps1")
    other("Outros programas") --> exe("ansible-playbook.exe")
    exe -. lê .-> config("ansible-playbook.shim")
    exe --> exeps1("exe\ansible-playbook.ps1")
    ps1 --> module("WinPlaybook")
    exeps1 --> module
```

Cada comando tem estes arquivos na pasta:

- `ansible-playbook.ps1`: o _script_ que o PowerShell executa. Ele carrega o
  módulo e passa para ele o nome do comando, os argumentos e o que chega pelo
  _pipeline_. No fim, devolve o código de saída do comando.
- `ansible-playbook.exe`: o executável para os outros programas, como o
  Prompt de Comando, editores e _scripts_ em outras linguagens, que não
  executam `.ps1`. O `Install-WinPlaybook` faz o _build_ dele com o compilador
  de C# do .NET Framework, que vem no Windows. Ele abre o PowerShell com o
  `exe\ansible-playbook.ps1` e repassa a entrada, a saída e o código de saída.
- `ansible-playbook.shim`: a configuração do `.exe`. Ao ser executado, o
  `.exe` lê esse arquivo para saber qual PowerShell abrir e com quais
  argumentos:

    ```text
    path = C:\Program Files\PowerShell\7\pwsh.exe
    args = -NoProfile -ExecutionPolicy Bypass -File "C:\Users\<usuário>\AppData\Local\WinPlaybook\bin\exe\ansible-playbook.ps1"
    ```

- `exe\ansible-playbook.ps1`: o _script_ que o `.exe` abre. O `.exe` passa os
  argumentos codificados, para que o PowerShell não interprete nenhum deles,
  e o _script_ os decodifica antes de chamar o módulo.

Por padrão, o `.shim` usa o PowerShell em que o `Install-WinPlaybook` foi
executado. Para usar outro, passe o parâmetro `-PowerShell` na instalação.

!!! tip "Dica"

    O Windows PowerShell 5.1 abre mais rápido que o PowerShell 7:
    `Install-WinPlaybook -PowerShell Desktop`.

## O que acontece quando você executa um comando

No exemplo abaixo, o comando é executado em `C:\infra`:

```powershell
PS C:\infra> ansible-playbook -i .\inventory\prod.yml .\playbooks\site.yml
```

```mermaid
sequenceDiagram
    actor user as Você
    participant shim as Shim
    participant module as Módulo WinPlaybook
    participant wsl as WSL
    participant distro as Distribuição WinPlaybook

    user->>shim: ansible-playbook ...
    shim->>module: comando e argumentos
    Note over module: converte os caminhos<br/>e as variáveis ANSIBLE_
    module->>wsl: wsl --distribution WinPlaybook ...
    wsl->>distro: inicia, se está parada
    distro->>distro: executa o ansible-playbook em /mnt/c/infra
    distro-->>user: saída do Ansible
    distro-->>module: código de saída
    module-->>user: código de saída
```

A distribuição enxerga todas as unidades do Windows, em `/mnt/c`, `/mnt/d` e
assim por diante. O comando roda na pasta da distribuição que corresponde à
pasta atual do terminal, então os caminhos relativos funcionam como no
Windows. Os argumentos chegam ao comando como o PowerShell os passou, sem que
um _shell_ do Linux interprete as aspas, o `$` ou o `*`.

Quando nada chega pelo _pipeline_, o comando lê o terminal, e os pedidos de
senha do Ansible, como os do `--ask-vault-pass` e do `--ask-become-pass`,
funcionam como no Linux.

## Conversão de caminhos

O Linux da distribuição não entende caminhos do Windows. Antes de chamar o
comando, o WinPlaybook passa para o formato do Linux os argumentos que são
caminhos do Windows e deixa os outros como estão. Cada caminho continua
apontando para o mesmo arquivo, agora visto de dentro da distribuição:

- um caminho com a letra da unidade vai para a pasta dela em `/mnt`;
- um caminho do disco da distribuição, em `\\wsl.localhost\WinPlaybook\`,
  vira o caminho dele no Linux;
- um caminho relativo com `\` passa a usar `/` quando começa com `.\` ou
  `..\`, ou quando a pasta dele existe, mesmo que o arquivo ainda não exista.

Isso vale também para um caminho depois de uma opção com `=` ou de um `@`.

Exemplos com a pasta atual em `C:\infra`, que tem as pastas `vars` e
`saida`:

| Argumento                                            | Na distribuição                      |
| ---------------------------------------------------- | ------------------------------------ |
| `.\playbooks\site.yml`                               | `./playbooks/site.yml`               |
| `C:\infra\inventory\prod.yml`                        | `/mnt/c/infra/inventory/prod.yml`    |
| `D:\outros\hosts.yml`                                | `/mnt/d/outros/hosts.yml`            |
| `--inventory=C:\infra\hosts.yml`                     | `--inventory=/mnt/c/infra/hosts.yml` |
| `@vars\prod.yml`                                     | `@vars/prod.yml`                     |
| `saida\relatorio.json`, que ainda não existe         | `saida/relatorio.json`               |
| `\\wsl.localhost\WinPlaybook\home\winplaybook\a.yml` | `/home/winplaybook/a.yml`            |
| `~web\d+`                                            | `~web\d+`, não é caminho             |

## Variáveis de ambiente

As variáveis do Windows que começam com `ANSIBLE_`, como o `ANSIBLE_CONFIG`,
chegam ao comando com os caminhos convertidos pelas mesmas regras dos
argumentos. Uma lista separada por `;`, como as do Windows, vira uma lista
separada por `:`, como as do Linux:

| Variável              | No Windows             | Na distribuição             |
| --------------------- | ---------------------- | --------------------------- |
| `ANSIBLE_CONFIG`      | `C:\infra\ansible.cfg` | `/mnt/c/infra/ansible.cfg`  |
| `ANSIBLE_ROLES_PATH`  | `C:\roles;D:\roles`    | `/mnt/c/roles:/mnt/d/roles` |

As outras variáveis chegam só quando estão no
[`WSLENV`](https://learn.microsoft.com/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv),
como em qualquer distribuição WSL. Uma variável `ANSIBLE_` que já está no
`WSLENV` chega do jeito que o `WSLENV` define, sem a conversão do
WinPlaybook.

## SSH

A pasta `.ssh` do Windows, em `C:\Users\<usuário>\.ssh`, é o `~/.ssh` da
distribuição. O ssh do Ansible usa as mesmas chaves, o mesmo `known_hosts` e
o mesmo `config` do Windows, sem cópias. Dentro da distribuição, a pasta
aparece com as permissões que o ssh exige, sem mudar as permissões dos
arquivos no Windows.

Se a pasta `.ssh` ainda não existia na instalação, a distribuição usa uma
pasta própria. Execute o `Install-WinPlaybook` de novo depois de criá-la.

## Limitações

- Chaves SSH com senha não funcionam: o agente SSH do Windows não chega à
  distribuição, e o Ansible não responde ao pedido de senha da chave.
- Os arquivos das unidades do Windows não são executáveis na distribuição.
  Um _script_ de inventário ou de senha do vault guardado nelas é lido como
  texto, e os programas do Windows não rodam de dentro da distribuição.
- O acesso aos arquivos das unidades do Windows é mais lento que ao disco da
  distribuição, o que pesa em projetos com muitos arquivos.
- Cada comando passa pelo WSL, e os _shims_ `.exe` abrem também um
  PowerShell. Isso soma um tempo ao início de cada execução, maior quando a
  distribuição está parada.
