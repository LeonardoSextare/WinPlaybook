# Configure Windows itself

With the `localhost_windows` host, playbooks configure the Windows computer
that Ansible runs on, with the `ansible.windows` modules. `localhost` is
still the control node, as in Ansible.

To see the feature working from scratch, follow the
[Your first playbook](first-playbook.md) tutorial.

## Turn on localhost_windows

Before it starts, `Install-WinPlaybook` asks whether you want to turn on
`localhost_windows`.
To turn it on later, run this in PowerShell:

```powershell
Enable-WinPlaybookLocalhost
```

!!! note "Administrator"

    Windows asks for administrator approval. If the OpenSSH Server feature
    isn't installed, the command installs it, which can take a few minutes.

The command creates the `WinPlaybookSshd` service, which only accepts
connections from the same computer and only accepts the key kept in the
WinPlaybook distribution. See what changes on the system in
[What WinPlaybook changes on the system](system-changes.md#localhost_windows).

---

## Test the connection

```powershell
ansible localhost_windows -m ansible.windows.win_ping
```

!!! success "Expected result"

    The output shows `"ping": "pong"`.

---

## Use it in playbooks

```yaml
- hosts: localhost_windows
  tasks:
    - name: Create the C:\Temp\example folder
      ansible.windows.win_file:
        path: C:\Temp\example
        state: directory
```

!!! tip "No inventory needed"

    The host doesn't need to be in the inventory and isn't in the `all` group,
    like `localhost`. Tasks run as your Windows user.

The available modules are in the documentation of the
[ansible.windows collection](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html).

---

## Turn off localhost_windows

```powershell
Disable-WinPlaybookLocalhost
```

The command deletes the `WinPlaybookSshd` service and uninstalls OpenSSH
Server, if WinPlaybook installed it. `Uninstall-WinPlaybook` also turns off
`localhost_windows`.

---

## If something goes wrong

See [localhost_windows problems](troubleshooting-localhost-windows.md).
