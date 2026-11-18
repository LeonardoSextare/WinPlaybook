# O que o WinPlaybook altera no sistema

Esta página lista tudo o que o WinPlaybook cria ou altera no sistema e o que
acontece com cada item na desinstalação. `%LOCALAPPDATA%` é `C:\Users\<usuário>\AppData\Local`.

## Instalação

| Item                                   | Onde                                                   | Na desinstalação            |
| -------------------------------------- | ------------------------------------------------------ | --------------------------- |
| Distribuição WSL `WinPlaybook`         | `%LOCALAPPDATA%\WinPlaybook\distro`                    | Apagada                     |
| Comandos do Ansible                    | `%LOCALAPPDATA%\WinPlaybook\bin`, ou a pasta do `-Path` | Apagados                    |
| Entrada no `PATH` do usuário           | A pasta dos comandos                                   | Removida                    |
| Configuração e aviso de versão nova    | `%LOCALAPPDATA%\WinPlaybook`                           | Apagados                    |
| Logs                                   | `%LOCALAPPDATA%\WinPlaybook\logs`                      | Apagados                    |
| Linha do autocomplete                  | `profile.ps1` do PowerShell 7 e do Windows PowerShell  | Removida; um perfil vazio é apagado |
| Pastas de _collections_ e _roles_      | `C:\Users\<usuário>\.ansible`                          | Apagadas só se vazias       |
| Pasta `.ssh`, quando não existe        | `C:\Users\<usuário>\.ssh`                              | Apagada só se vazia         |

---

## Extensão do VS Code

Com o `Enable-WinPlaybookVSCodeExtension`:

| Item                         | Onde                                                    | Na desinstalação     |
| ---------------------------- | ------------------------------------------------------- | -------------------- |
| Arquivos corrigidos          | `C:\Users\<usuário>\.vscode\extensions\redhat.ansible-*` | Originais devolvidos |
| Cópia dos arquivos originais | Ao lado de cada arquivo, com `.winplaybook-original`    | Apagada              |

---

## localhost_windows

Com o `Enable-WinPlaybookLocalhost`:

| Item                    | Onde                              | Na desinstalação                        |
| ----------------------- | --------------------------------- | --------------------------------------- |
| Recurso OpenSSH Server  | Recursos opcionais do Windows     | Desinstalado se o WinPlaybook o instalou |
| Serviço `WinPlaybookSshd` | Serviços do Windows             | Apagado                                 |
| Configuração do serviço | `C:\ProgramData\WinPlaybook\ssh`  | Apagada                                 |

---

## O que o WinPlaybook não altera

- As suas distribuições WSL.
- As configurações do VS Code.
- Os arquivos da pasta `.ssh`. Só o `ssh` grava nela, como faria no Windows,
  por exemplo ao acrescentar um host ao `known_hosts`.
- O `sshd` do Windows e a configuração dele.
