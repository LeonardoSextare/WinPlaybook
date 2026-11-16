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

As próximas execuções do `Install-WinPlaybook` mantêm essas escolhas. Para
voltar à versão mais nova, passe `-AnsibleVersion ''`. Para tirar os pacotes,
passe `-PythonPackage @()`.

## Atualizar

Atualize o módulo com o comando da sua versão do PowerShell:

- PowerShell 7.4 em diante: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

Se você instalou pelo código-fonte, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook` e repita os
passos 1 e 2 com o código novo.

Depois, atualize o Ansible e os comandos:

```powershell
Install-WinPlaybook
```

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
