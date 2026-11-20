# Problemas ao rodar comandos

## O WinPlaybook não está instalado

!!! failure "Mensagem de erro"

    ```text
    O WinPlaybook não está instalado. Instale com: Install-WinPlaybook
    ```

O módulo está instalado, mas o `Install-WinPlaybook` ainda não rodou, ou o
`Uninstall-WinPlaybook` já rodou. Rode o `Install-WinPlaybook`.

---

## A distribuição não existe mais

!!! failure "Mensagem de erro"

    ```text
    A distribuição WSL WinPlaybook do WinPlaybook não existe mais. Instale de novo com: Install-WinPlaybook
    ```

A distribuição foi apagada fora do WinPlaybook, como por um
`wsl --unregister`. Rode o `Install-WinPlaybook`, que cria uma nova.

---

## Um comando não existe na distribuição

!!! failure "Mensagem de erro"

    ```text
    WinPlaybook: comando ansible-xyz ausente na distribuição WSL. Rode o Install-WinPlaybook para atualizar os comandos.
    ```

O comando ficou de uma instalação anterior, ou de um pacote que você tirou do
`-PythonPackage`. Rode o `Install-WinPlaybook`.

Num projeto com [ambiente próprio](project-environment.md), só funcionam os
comandos que o `pyproject.toml` declara. Acrescente o pacote às
dependências.

---

## OSError: [WinError 87] num projeto com pyproject.toml

!!! failure "Mensagem de erro"

    ```text
    OSError: [WinError 87] Parâmetro incorreto
    ```

O comando rodou o Ansible do Windows que um `uv sync` no Windows instalou na
`.venv` do projeto, e não o do WinPlaybook. Marque o Ansible com
`; sys_platform == 'linux'` no `pyproject.toml` e rode `uv sync`. Veja
[Usar um ambiente por projeto](project-environment.md#por-que-o-marcador-sys_platform).

---

## O primeiro comando demora

O primeiro comando depois de ligar o Windows leva alguns segundos a mais,
porque o WSL inicia a distribuição. Os comandos seguintes começam mais rápido.
O primeiro comando num projeto com [ambiente próprio](project-environment.md)
também demora mais, porque instala os pacotes.

---

## Uma unidade ou um compartilhamento não é acessível

!!! failure "Mensagem de erro"

    ```text
    Não foi possível acessar \\servidor\infra na distribuição WSL. Confira se a unidade ou o compartilhamento está acessível no Windows e tente de novo.
    ```

Abra a pasta no Explorador de Arquivos. Se o Windows pedir credenciais,
informe e rode o comando de novo.

---

## Um caminho do Windows não funciona

O WinPlaybook converte os caminhos do Windows nos argumentos, nos arquivos do
Ansible e nas variáveis de ambiente. Um texto que não parece um caminho fica
como está. Se um caminho relativo com `\` não é convertido, comece-o com `.\`:

```powershell
ansible-playbook .\playbooks\site.yml
```

Veja as regras em [Caminhos entre o Windows e o Linux](paths.md).

---

## Uma tarefa não alcança um serviço do Windows no localhost

Um `uri` ou um `wait_for` para `localhost:8080` dá `Connection refused`,
mas o navegador do Windows abre o serviço.

- Confira se o serviço escuta no `127.0.0.1`, no `::1` ou em todas as
  interfaces. Um serviço que escuta só no IP da placa de rede não é alcançado
  pelo `localhost`.
- Se a distribuição também tem um serviço na mesma porta, a conexão fica nela.
- Se o serviço acabou de abrir, rode o comando de novo. A lista de portas do
  Windows é atualizada a cada segundo.

Veja [Rede](network.md).

---

## O ansible.cfg do projeto é ignorado

Rode o comando na pasta do projeto, ou numa subpasta dele. O Ansible procura o
`ansible.cfg` na pasta atual. Sem um `ansible.cfg` no projeto, ele usa o
`C:\Users\<usuário>\.ansible.cfg`.

Confira qual arquivo está em uso:

```powershell
ansible --version
```

A linha `config file` mostra o arquivo.

---

## Outro erro

Veja [Consultar os logs](logs.md) e [Reportar um problema](report-issue.md).
