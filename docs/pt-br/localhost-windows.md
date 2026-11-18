# Configurar o próprio Windows

Com o host `localhost_windows`, os _playbooks_ configuram a máquina Windows em
que o Ansible roda, com os módulos `ansible.windows`. O `localhost` continua
sendo o nó de controle, como no Ansible.

## Ligar o localhost_windows

O `Install-WinPlaybook` pergunta se você quer ligar o `localhost_windows`.
Para ligar depois, execute no PowerShell:

```powershell
Enable-WinPlaybookLocalhost
```

O Windows pede a aprovação de administrador. O comando instala o recurso
OpenSSH Server quando ele falta, o que pode levar alguns minutos, e cria o
serviço `WinPlaybookSshd`, que só aceita conexões da própria máquina.

## Testar a conexão

```powershell
ansible localhost_windows -m ansible.windows.win_ping
```

O resultado é `"ping": "pong"`.

## Usar nos playbooks

```yaml
- hosts: localhost_windows
  tasks:
    - name: Cria a pasta C:\Temp\exemplo
      ansible.windows.win_file:
        path: C:\Temp\exemplo
        state: directory
```

O host não precisa estar no inventário e fica fora do grupo `all`, como o
`localhost`. As tarefas rodam com o seu usuário do Windows.

## Desligar o localhost_windows

```powershell
Disable-WinPlaybookLocalhost
```

O comando apaga o serviço `WinPlaybookSshd` e desinstala o OpenSSH Server
quando foi o WinPlaybook que o instalou. O `Uninstall-WinPlaybook` também
desliga o `localhost_windows`.
