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

    Windows asks for administrator approval. The first time, the command
    downloads OpenSSH from the official Microsoft release on GitHub, without
    installing anything on Windows.

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

## Set variables

`localhost_windows` gets variables like any host: the
`host_vars/localhost_windows.yml` and `group_vars/all.yml` files of the
project apply to it, even without an inventory.

```yaml
# host_vars/localhost_windows.yml
work_folder: C:\Work
```

The tasks run over SSH with the default shell of the Windows OpenSSH: `cmd`,
or PowerShell, if you chose it as the
[DefaultShell](https://learn.microsoft.com/windows-server/administration/openssh/openssh-server-configuration#configuring-the-default-shell-for-openssh-in-windows).
WinPlaybook follows that choice. The difference only shows in
`ansible.builtin.raw`, which runs in that shell. The `ansible.windows` modules,
such as `win_shell`, use PowerShell in both cases.

---

## Restart Windows

Ansible runs on Windows itself, so a restart stops the command in the middle,
and the playbook doesn't continue after Windows comes back. Don't use
`ansible.windows.win_reboot` on `localhost_windows`.

Leave the restart for the end, with time for the command to finish:

```yaml
- name: Schedule the restart in one minute
  ansible.windows.win_command: shutdown.exe /r /t 60
  when: restart_pending | default(false)
```

Or keep the `reboot_required` value that modules such as `win_feature` return
and show a message at the end, so that you restart when you can.

---

## Turn off localhost_windows

```powershell
Disable-WinPlaybookLocalhost
```

The command deletes the `WinPlaybookSshd` service and the OpenSSH that
WinPlaybook downloaded. `Uninstall-WinPlaybook` also turns off
`localhost_windows`.

---

## If something goes wrong

See [localhost_windows problems](troubleshooting-localhost-windows.md).
