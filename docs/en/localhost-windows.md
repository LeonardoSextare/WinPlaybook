# Configure Windows itself

With the `localhost_windows` host, playbooks configure the Windows machine
that Ansible runs on, with the `ansible.windows` modules. `localhost` is
still the control node, as in Ansible.

## Turn on localhost_windows

`Install-WinPlaybook` asks whether you want to turn on `localhost_windows`.
To turn it on later, run this in PowerShell:

```powershell
Enable-WinPlaybookLocalhost
```

Windows asks for administrator approval. The command installs the OpenSSH
Server feature when it's missing, which can take a few minutes, and creates
the `WinPlaybookSshd` service, which only accepts connections from the same
machine.

## Test the connection

```powershell
ansible localhost_windows -m ansible.windows.win_ping
```

The result is `"ping": "pong"`.

## Use it in playbooks

```yaml
- hosts: localhost_windows
  tasks:
    - name: Create the C:\Temp\example folder
      ansible.windows.win_file:
        path: C:\Temp\example
        state: directory
```

The host doesn't need to be in the inventory and isn't in the `all` group,
like `localhost`. Tasks run as your Windows user.

## Turn off localhost_windows

```powershell
Disable-WinPlaybookLocalhost
```

The command deletes the `WinPlaybookSshd` service and uninstalls OpenSSH
Server when WinPlaybook installed it. `Uninstall-WinPlaybook` also turns off
`localhost_windows`.
