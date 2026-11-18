# Connect to servers over SSH

Ansible connects to servers with the keys, the `known_hosts` file, and the
`config` file of your Windows `.ssh` folder, in `C:\Users\<user>\.ssh`. If
the Windows `ssh` connects to a server, Ansible connects too.

## Create a key

If you don't have a key yet, create one in PowerShell:

```powershell
ssh-keygen -t ed25519
```

Copy the public key (`C:\Users\<user>\.ssh\id_ed25519.pub`) to the
`~/.ssh/authorized_keys` file on the server.

---

## Test the connection

With an inventory that has the server:

```yaml
servers:
  hosts:
    web1:
      ansible_host: 192.168.0.10
      ansible_user: deploy
```

```powershell
ansible -i inventory.yml servers -m ansible.builtin.ping
```

!!! tip "Default user"

    Without an `ansible_user`, Ansible uses your Windows user name, like the
    Windows `ssh`.

---

## Use a key with a passphrase

!!! info "Why the agent"

    Ansible doesn't answer the passphrase prompt of a key. To use a key with a
    passphrase, turn on the Windows SSH agent and add the key to it. WinPlaybook
    finds the agent by itself.

1. In PowerShell as an administrator, turn on the agent and set it to start
   with Windows:

    ```powershell
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ```

2. In your terminal, add the key and type the passphrase:

    ```powershell
    ssh-add $env:USERPROFILE\.ssh\id_ed25519
    ```

    The agent keeps the key, so you don't repeat this step after you restart
    Windows.

3. Check that Ansible sees the key:

    ```powershell
    Invoke-WinPlaybook ssh-add -l
    ```

    The output shows the key that you added.

---

## Use the config file of the .ssh folder

The `config` file of the `.ssh` folder applies to Ansible, including Windows
paths, such as in an `IdentityFile` or in a `ProxyCommand` with `ssh.exe`:

```text
Host bastion
    HostName bastion.company.com
    User deploy
    IdentityFile C:\Users\me\.ssh\company

Host 10.0.*
    ProxyJump bastion
```

---

## Manage remote Windows computers

For Windows computers on the network, Ansible uses WinRM or SSH, as on Linux.
`pywinrm` is already installed. See the
[Ansible Windows guide](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html).
To configure your own computer, see
[Configure Windows itself](localhost-windows.md).
