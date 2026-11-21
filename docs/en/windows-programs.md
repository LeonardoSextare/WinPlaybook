# Run Windows programs and scripts

The programs in your Windows `Path` work in the tasks that run on
`localhost`, and the project scripts run by their extension, as on Windows.

## Run a program from the Path

In an `ansible.builtin.command` or `ansible.builtin.shell` task, call the
program by its name, with or without the extension:

```yaml
- name: List the open pull requests
  ansible.builtin.command: gh pr list
  delegate_to: localhost
```

Programs with the `.com`, `.exe`, `.bat`, and `.cmd` extensions work, in the
order of `Path` and `PATHEXT`, as on Windows. Arguments that are paths, such
as `{{ playbook_dir }}`, reach the program as Windows paths.

!!! warning "Two things to keep in mind"

    Keep two things in mind:

    - When a name exists on Windows and on the WinPlaybook Linux, such as `git`
      and `ssh`, the Linux one runs. For the Windows one, use the extension:
      `git.exe`.
    - The Windows Python only runs with the extension: `python.exe`.

---

## Call a program in the pipe lookup

In `lookup('pipe')`, a command that starts with a Windows program gets its
arguments as on Windows, without a Linux shell interpreting the quotes and the
`$`:

```yaml
- name: Get the IP address of a Hyper-V virtual machine
  ansible.builtin.set_fact:
    vm_ip: >-
      {{ lookup('pipe', 'powershell.exe -NoProfile -Command "(Get-VM test | Get-VMNetworkAdapter).IPAddresses[0]"') }}
```

A command that uses `|`, `&&`, `;`, `<`, or `>` outside quotes goes through
`sh`, as on Linux.

!!! note "In the shell module"

    `ansible.builtin.shell` always sends the command through the Linux `sh`,
    as in regular Ansible. To call PowerShell with quotes and `$`, use
    `ansible.builtin.command` with `argv`:

    ```yaml
    - name: Show the computer name
      ansible.builtin.command:
        argv: [powershell.exe, -NoProfile, -Command, "Write-Output $env:COMPUTERNAME"]
      delegate_to: localhost
    ```

---

## Run a project script

A project script runs by its extension, as on Windows:

| Extension       | Runs with                                                   |
| --------------- | ----------------------------------------------------------- |
| `.ps1`          | `powershell.exe`                                            |
| `.bat` and `.cmd` | `cmd.exe`                                                 |
| `.exe` and `.com` | Directly                                                  |
| `.py` and `.sh` | The file shebang, or the Ansible Python and `sh`            |

This also applies to the files that Ansible runs, such as a dynamic inventory
or a vault password file:

```powershell
ansible-playbook -i .\inventory.ps1 --vault-password-file .\password.bat site.yml
```

Other files, such as `password.txt`, are still read as text.

---

## Use the Windows editor with the vault

`ansible-vault create` and `ansible-vault edit` open the editor in the Windows
`EDITOR` variable. Without it, they open Notepad. To use VS Code:

```powershell
$env:EDITOR = 'code --wait'
ansible-vault edit secrets.yml
```

---

## Call a service on the Windows localhost

A service that listens on the Windows `localhost`, such as an API in
development or a Docker Desktop container, also answers on the `localhost` of
the tasks:

```yaml
- name: Wait for the API to start
  ansible.builtin.wait_for:
    port: 8080
  delegate_to: localhost
```
