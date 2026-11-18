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

Na primeira vez, o comando baixa o Debian e o Ansible, o que leva alguns
minutos. No fim, ele pergunta se você quer ligar o `localhost_windows`, que
deixa os _playbooks_ configurarem o próprio Windows. Para decidir depois, veja
[Configurar o próprio Windows](localhost-windows.md).

Teste no mesmo terminal:

```powershell
ansible --version
```

!!! note "Terminais abertos"

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

## Próximo passo

Rode o [seu primeiro playbook](first-playbook.md).
