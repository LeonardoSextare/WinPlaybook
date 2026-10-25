# Instalar o WinPlaybook

Escolha uma das três formas de instalação. A mais rápida é o script de
instalação. Nenhuma delas pede permissão de administrador.

## Requisitos

| Requisito      | Versão                                             |
| -------------- | -------------------------------------------------- |
| Windows        | 10 22H2 ou 11 23H2 em diante, 64 bits              |
| Docker Desktop | com o backend WSL 2 e *containers* Linux           |
| PowerShell     | Windows PowerShell 5.1 ou PowerShell 7.4 em diante |

---

## Script de instalação

Execute no PowerShell:

```powershell
irm https://leonardosextare.github.io/WinPlaybook/install.ps1 | iex
```

Na primeira vez, a instalação pode levar alguns minutos, por causa do
download da imagem do Ansible.

Abra um terminal novo e teste:

```powershell
ansible --version
```

Para atualizar, execute o script de novo ou use o comando da sua versão do
PowerShell:

- PowerShell 7.4 em diante: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

---

## PowerShell Gallery

Esta forma usa os comandos do próprio PowerShell, sem o script de instalação.

Se o `Get-ExecutionPolicy` mostrar `Restricted` ou `AllSigned`, libere os
scripts locais para o seu usuário:

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

Crie os comandos do Ansible. Na primeira vez, o comando baixa a imagem:

```powershell
Install-WinPlaybookShim
```

Abra um terminal novo e teste com `ansible --version`.

Para atualizar, use `Update-PSResource WinPlaybook` no PowerShell 7.4 em
diante ou `Update-Module WinPlaybook` no Windows PowerShell 5.1.

---

## Código-fonte

Esta forma faz o *build* da imagem e do módulo na sua máquina. Além dos
requisitos acima, você precisa do [Git](https://git-scm.com/) e do
PowerShell 7.4 em diante. Execute todos os passos no PowerShell 7.

1. Clone o repositório:

    ```powershell
    git clone https://github.com/LeonardoSextare/WinPlaybook.git
    cd WinPlaybook
    ```

2. Faça o *build* da imagem e configure o WinPlaybook para usá-la:

    ```powershell
    docker build --tag winplaybook:local image
    [Environment]::SetEnvironmentVariable('WINPLAYBOOK_IMAGE', 'winplaybook:local', 'User')
    $env:WINPLAYBOOK_IMAGE = 'winplaybook:local'
    ```

3. Instale o módulo na pasta de módulos do PowerShell 7:

    ```powershell
    $modulesFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    ./scripts/Build-ModulePackage.ps1 -Version 0.0.0 -Destination $modulesFolder
    ```

4. Crie os comandos do Ansible:

    ```powershell
    Install-WinPlaybookShim
    ```

5. Abra um terminal novo e teste com `ansible --version`.

Depois da instalação, você pode apagar o repositório clonado.

Para atualizar, apague a pasta
`C:\Users\<usuário>\Documents\PowerShell\Modules\WinPlaybook` e repita os
passos com o código novo.
