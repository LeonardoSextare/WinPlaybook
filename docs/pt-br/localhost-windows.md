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

## Definir variáveis

O `localhost_windows` recebe as variáveis como qualquer host: o
`host_vars/localhost_windows.yml` e o `group_vars/all.yml` do projeto valem
para ele, mesmo sem inventário.

```yaml
# host_vars/localhost_windows.yml
pasta_de_trabalho: C:\Trabalho
```

As tarefas rodam pelo SSH com o shell padrão do OpenSSH do Windows: o `cmd`,
ou o PowerShell, se você o escolheu como
[DefaultShell](https://learn.microsoft.com/windows-server/administration/openssh/openssh-server-configuration#configuring-the-default-shell-for-openssh-in-windows).
O WinPlaybook segue essa escolha. A diferença só aparece no
`ansible.builtin.raw`, que roda nesse shell. Os módulos `ansible.windows`,
como o `win_shell`, usam o PowerShell nos dois casos.

---

## Reiniciar o Windows

O Ansible roda no próprio Windows, então um reinício encerra o comando no
meio, e o _playbook_ não continua depois que o Windows volta. Não use o
`ansible.windows.win_reboot` no `localhost_windows`.

Deixe o reinício para o fim, com um tempo para o comando terminar:

```yaml
- name: Agenda o reinício para daqui a um minuto
  ansible.windows.win_command: shutdown.exe /r /t 60
  when: reinicio_pendente | default(false)
```

Ou guarde o `reboot_required` que módulos como o `win_feature` devolvem e
avise no fim, para você reiniciar quando puder.

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
