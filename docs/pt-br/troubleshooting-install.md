# Problemas na instalação

## O WSL não está instalado

!!! failure "Mensagem de erro"

    ```text
    O WSL não está instalado. Instale com: wsl --install --no-distribution ...
    ```

Num PowerShell como administrador:

```powershell
wsl --install --no-distribution
```

Reinicie o Windows se ele pedir e rode o `Install-WinPlaybook` de novo.

---

## A virtualização está desligada

O `wsl --install` termina, mas o `Install-WinPlaybook` falha ao criar a
distribuição, com uma mensagem do WSL sobre virtualização ou sobre a
Plataforma de Máquina Virtual.

1. Num PowerShell como administrador, ligue o recurso:

    ```powershell
    wsl --install --no-distribution
    ```

2. Confira se a virtualização está ligada na BIOS ou na UEFI da máquina. No
   Gerenciador de Tarefas, aba **Desempenho**, **CPU**, o campo
   **Virtualização** mostra **Habilitado**.

3. Reinicie o Windows e rode o `Install-WinPlaybook` de novo.

---

## O PowerShell não deixa rodar scripts

!!! failure "Mensagem de erro"

    ```text
    ... não pode ser carregado porque a execução de scripts foi desabilitada neste sistema.
    ```

Libere os _scripts_ locais para o seu usuário:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Se a sua empresa controla essa política, o comando não muda nada. Fale com o
time que administra as máquinas.

---

## A distribuição não foi criada

!!! failure "Mensagem de erro"

    ```text
    Não foi possível criar a distribuição WSL WinPlaybook. Confira a conexão com a internet e se o WSL está atualizado (wsl --update).
    ```

1. Atualize o WSL:

    ```powershell
    wsl --update
    ```

2. Confira se o Windows acessa a internet.

3. Rode o `Install-WinPlaybook` de novo.

---

## O Ansible não foi instalado

!!! failure "Mensagem de erro"

    ```text
    Não foi possível instalar o Ansible na distribuição WSL WinPlaybook. Confira a versão do Ansible, os pacotes Python e a conexão com a internet ...
    ```

A mensagem termina com a resposta do uv, que diz o que falhou. As causas
comuns são:

- uma versão do Ansible que não existe, no `-AnsibleVersion`;
- um pacote com o nome errado, no `-PythonPackage`;
- falta de acesso ao PyPI, o repositório de pacotes do Python.

Corrija e rode o `Install-WinPlaybook` de novo.

---

## O compilador de C# não foi encontrado

!!! failure "Mensagem de erro"

    ```text
    O compilador de C# do .NET Framework não está em ...
    ```

Instale o [.NET Framework 4.8](https://dotnet.microsoft.com/download/dotnet-framework/net48)
e rode o `Install-WinPlaybook` de novo.

---

## A pasta já existe

!!! failure "Mensagem de erro"

    ```text
    A pasta ... já existe e não foi criada pelo WinPlaybook.
    ```

O `-Path` aponta para uma pasta `WinPlaybook` que não é do WinPlaybook.
Escolha outro `-Path` ou apague a pasta.

---

## O comando não é encontrado depois da instalação

!!! failure "Mensagem de erro"

    ```text
    ansible : O termo 'ansible' não é reconhecido ...
    ```

Feche e abra o terminal. Os terminais e os programas abertos antes da
instalação não enxergam a pasta nova do `PATH`.
