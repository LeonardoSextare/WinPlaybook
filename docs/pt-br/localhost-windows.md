# Configurar o próprio Windows

Com o host `localhost_windows`, os _playbooks_ configuram a máquina Windows em
que o Ansible roda, com os módulos `ansible.windows`. O `localhost` continua
sendo o nó de controle, como no Ansible.

Para ver o recurso funcionando do zero, siga o tutorial
[Seu primeiro playbook](first-playbook.md).

## Ligar o localhost_windows

Antes de começar, o `Install-WinPlaybook` pergunta se você quer ligar o
`localhost_windows`.
Para ligar depois, execute no PowerShell:

```powershell
Enable-WinPlaybookLocalhost
```

!!! note "Administrador"

    O Windows pede a aprovação de administrador. Na primeira vez, o comando
    baixa o OpenSSH da release oficial da Microsoft no GitHub, sem instalar
    nada no Windows.

O comando cria o serviço `WinPlaybookSshd`, que só aceita conexões da própria
máquina e só aceita a chave guardada na distribuição do WinPlaybook. Veja o
que muda no sistema em [O que o WinPlaybook altera no sistema](system-changes.md#localhost_windows).

---

## Testar a conexão

```powershell
ansible localhost_windows -m ansible.windows.win_ping
```

!!! success "Resultado esperado"

    A saída mostra `"ping": "pong"`.

---

## Usar nos playbooks

```yaml
- hosts: localhost_windows
  tasks:
    - name: Cria a pasta C:\Temp\exemplo
      ansible.windows.win_file:
        path: C:\Temp\exemplo
        state: directory
```

!!! tip "Sem inventário"

    O host não precisa estar no inventário e não faz parte do grupo `all`,
    como o `localhost`. As tarefas rodam com o seu usuário do Windows.

Os módulos disponíveis estão na documentação da
[collection ansible.windows](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html).

---

## Desligar o localhost_windows

```powershell
Disable-WinPlaybookLocalhost
```

O comando apaga o serviço `WinPlaybookSshd` e o OpenSSH que o WinPlaybook
baixou. O `Uninstall-WinPlaybook` também desliga
o `localhost_windows`.

---

## Se algo der errado

Veja [Problemas no localhost_windows](troubleshooting-localhost-windows.md).
