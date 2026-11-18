# Conectar em servidores por SSH

O Ansible conecta nos servidores com as chaves, o `known_hosts` e o `config`
da sua pasta `.ssh` do Windows, em `C:\Users\<usuário>\.ssh`. Se o `ssh` do
Windows já conecta num servidor, o Ansible também conecta.

## Criar uma chave

Se você ainda não tem uma chave, crie no PowerShell:

```powershell
ssh-keygen -t ed25519
```

Copie a chave pública (`C:\Users\<usuário>\.ssh\id_ed25519.pub`) para o
`~/.ssh/authorized_keys` do servidor.

---

## Testar a conexão

Num inventário com o servidor:

```yaml
servidores:
  hosts:
    web1:
      ansible_host: 192.168.0.10
      ansible_user: deploy
```

```powershell
ansible -i inventario.yml servidores -m ansible.builtin.ping
```

!!! tip "Usuário padrão"

    Sem um `ansible_user`, o Ansible usa o seu nome de usuário do Windows, como o
    `ssh` do Windows.

---

## Usar uma chave com passphrase

!!! info "Por que o agente"

    O Ansible não responde ao pedido de passphrase de uma chave. Para usar uma
    chave com passphrase, ligue o agente SSH do Windows e adicione a chave a ele.
    O WinPlaybook encontra o agente sozinho.

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

3. Confira se o Ansible enxerga a chave:

    ```powershell
    Invoke-WinPlaybook ssh-add -l
    ```

    A saída mostra a chave que você adicionou.

---

## Usar o config da pasta .ssh

O `config` da pasta `.ssh` vale para o Ansible, inclusive com caminhos do
Windows, como num `IdentityFile` ou num `ProxyCommand` com o `ssh.exe`:

```text
Host bastiao
    HostName bastiao.empresa.com
    User deploy
    IdentityFile C:\Users\eu\.ssh\empresa

Host 10.0.*
    ProxyJump bastiao
```

---

## Gerenciar máquinas Windows remotas

Para máquinas Windows na rede, o Ansible usa o WinRM ou o SSH, como no
Linux. O `pywinrm` já vem instalado. Veja o
[guia de Windows do Ansible](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html).
Para configurar a sua própria máquina, veja
[Configurar o próprio Windows](localhost-windows.md).
