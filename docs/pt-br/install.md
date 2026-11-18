# Instalar o WinPlaybook

Escolha uma das duas formas de instalação. A mais rápida é a PowerShell
Gallery. Nenhuma delas pede permissão de administrador.

## Requisitos

| Requisito  | Versão                                             |
| ---------- | -------------------------------------------------- |
| Windows    | 10 ou 11                                           |
| WSL        | 2, na versão mais recente                          |
| PowerShell | Windows PowerShell 5.1 ou PowerShell 7.4 em diante |

---

## PowerShell Gallery

Se o `Get-ExecutionPolicy` mostrar `Restricted` ou `AllSigned`, libere os
_scripts_ locais para o seu usuário:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Instale o módulo:

=== "PowerShell 7.4 em diante"

    ```powershell
    Install-PSResource WinPlaybook -Scope CurrentUser
    ```

=== "Windows PowerShell 5.1"

    ```powershell
    Install-Module WinPlaybook -Scope CurrentUser
    ```

    Na primeira vez, o Windows PowerShell 5.1 pede para instalar o provedor
    NuGet.

O PowerShell pergunta se você confia na PowerShell Gallery. Confirme para
instalar.

Instale o Ansible e crie os comandos dele no Windows:

```powershell
Install-WinPlaybook
```

Na primeira vez, o comando cria a distribuição WSL `WinPlaybook`, com o
Debian, e instala o Ansible nela. Isso leva alguns minutos.

Teste no mesmo terminal:

```powershell
ansible --version
```

Os terminais e os programas que já estavam abertos, como o VS Code, só
encontram os comandos depois de reabertos.

---

## Código-fonte

Esta forma faz o _build_ do módulo na sua máquina. Além dos requisitos
acima, você precisa do [Git](https://git-scm.com/) e do PowerShell 7.4 em
diante. Execute todos os passos no PowerShell 7.

1. Clone o repositório:

    ```powershell
    git clone https://github.com/LeonardoSextare/WinPlaybook.git
    cd WinPlaybook
    ```

2. Instale o módulo na pasta de módulos do PowerShell 7:

    ```powershell
    ./scripts/Build-PacoteDoModulo.ps1 -Versao 0.0.0 -PastaDeDestino (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules')
    ```

3. Instale o Ansible e crie os comandos dele no Windows:

    ```powershell
    Install-WinPlaybook
    ```

4. Teste com `ansible --version`.

Depois da instalação, você pode apagar o repositório clonado.

---

## Escolher a versão do Ansible

O `Install-WinPlaybook` instala a versão mais nova do Ansible. Para usar outra
versão, ou para instalar junto os pacotes Python que uma _collection_ pede,
passe os parâmetros:

```powershell
Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'
```

Uma ferramenta instalada assim, como o `molecule` ou o `yamllint`, ganha um
comando no Windows, como os do Ansible:

```powershell
Install-WinPlaybook -PythonPackage 'molecule', 'yamllint'
yamllint .
```

As próximas execuções do `Install-WinPlaybook` mantêm essas escolhas. Para
voltar à versão mais nova, passe `-AnsibleVersion ''`. Para tirar os pacotes,
passe `-PythonPackage @()`.

## Usar um ambiente por projeto

Um projeto pode fixar a própria versão do Ansible e dos pacotes Python com um
`pyproject.toml` do [uv](https://docs.astral.sh/uv/), com o `ansible` ou o
`ansible-core` nas dependências:

```toml
[project]
name = "infra"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["ansible-core==2.19.*", "ansible-lint", "boto3"]
```

Na pasta do projeto, ou numa subpasta, os comandos do Ansible usam esse
ambiente, como o `uv run` faria. Na primeira vez, o WinPlaybook instala os
pacotes, e o uv grava o `uv.lock` no projeto. As instalações do
`Install-WinPlaybook` ficam de fora: um comando que o projeto não declara, como
o `molecule` nesse exemplo, não funciona nesse projeto. O ambiente fica
no disco da distribuição, e a pasta do projeto não ganha uma `.venv`.

Uma ferramenta que o projeto declara, como o `yamllint`, ganha um comando no
Windows depois do primeiro comando do WinPlaybook na pasta do projeto.

## Usar o autocomplete no PowerShell

Depois da instalação, num terminal novo do PowerShell, a tecla Tab completa as
opções dos comandos do Ansible, como `ansible-playbook --che` para `--check`, e
os subcomandos, como `ansible-galaxy co` para `collection`. Os caminhos
continuam sendo completados como em qualquer comando. Para isso, o
`Install-WinPlaybook` acrescenta uma linha ao perfil do PowerShell 7 e ao do
Windows PowerShell, e o `Uninstall-WinPlaybook` a tira.

Num projeto com ambiente próprio, o autocomplete precisa do pacote
`argcomplete` nas dependências do `pyproject.toml`.

## Usar chaves SSH com passphrase

O Ansible não responde ao pedido de passphrase de uma chave SSH. Para usar
uma chave com passphrase, ligue o agente SSH do Windows e adicione a chave a
ele. O WinPlaybook encontra o agente sozinho.

1. Num PowerShell como administrador, ligue o agente e deixe-o iniciar com o
   Windows:

    ```powershell
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ```

2. No seu terminal, adicione a chave e digite a passphrase:

    ```powershell
    ssh-add $env:USERPROFILE\.ssh\id_ed25519
    ```

    O agente guarda a chave, então você não repete esse passo depois de
    reiniciar o Windows.

3. Confira se a distribuição enxerga a chave:

    ```powershell
    Invoke-WinPlaybook ssh-add -l
    ```

    A saída mostra a chave que você adicionou.

## Atualizar

Atualize o módulo, o Ansible e os comandos de uma vez:

```powershell
Update-WinPlaybook
```

O WinPlaybook avisa quando existe uma versão nova, na primeira vez que você
roda um comando dele no terminal. Para desligar o aviso, defina a variável de
ambiente `WINPLAYBOOK_UPDATE_CHECK` como `off`.

Se você instalou pelo código-fonte, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook`, repita os
passos 1 e 2 com o código novo e rode o `Install-WinPlaybook`.

## Desinstalar

Apague a distribuição e os comandos do Ansible:

```powershell
Uninstall-WinPlaybook
```

O comando pede confirmação, porque a distribuição é apagada com tudo o que
há nela, como as _collections_ e as _roles_ que o `ansible-galaxy` instalou.

Depois, remova o módulo:

- PowerShell 7.4 em diante: `Uninstall-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Uninstall-Module WinPlaybook`

Se você instalou pelo código-fonte, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook`.
