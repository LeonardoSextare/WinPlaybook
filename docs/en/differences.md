# Differences from Ansible on Linux

The WinPlaybook Ansible is the official Ansible, and the
[Ansible documentation](https://docs.ansible.com/) applies to it. This page
only lists what changes because it runs from Windows.

## Hosts

| Host                | What it is                                                         |
| ------------------- | ------------------------------------------------------------------ |
| `localhost`         | The control node: the Linux where Ansible runs, as in regular Ansible |
| `localhost_windows` | Your Windows computer, when [turned on](localhost-windows.md)      |

Both exist without being in the inventory and aren't in the `all` group.

---

## Paths

- Windows paths work in the arguments, in the Ansible files, such as
  playbooks, inventories, and `ansible.cfg`, and in the environment
  variables. See [Paths between Windows and Linux](paths.md).
- The output shows paths in the Windows format: `C:\infra\site.yml`.
- Inside the tasks that run on `localhost`, such as in `{{ playbook_dir }}`,
  the paths are the Linux ones: `/mnt/c/infra`.

---

## User folders

| What                    | On Linux                 | With WinPlaybook                        |
| ----------------------- | ------------------------ | --------------------------------------- |
| Collections             | `~/.ansible/collections` | `C:\Users\<user>\.ansible\collections`  |
| Roles                   | `~/.ansible/roles`       | `C:\Users\<user>\.ansible\roles`        |
| Plugins                 | `~/.ansible/plugins`     | `C:\Users\<user>\.ansible\plugins`      |
| User configuration      | `~/.ansible.cfg`         | `C:\Users\<user>\.ansible.cfg`          |
| ssh keys and configuration | `~/.ssh`              | `C:\Users\<user>\.ssh`                  |

The default `ssh` user is your Windows user name.

---

## Programs and scripts

- The programs in the Windows `Path` work in the `localhost` tasks. When a
  name exists on both sides, such as `git`, the Linux one runs.
- Project scripts run by their extension: `.ps1` with PowerShell, `.bat` with
  `cmd.exe`, without the Linux execute permission.
- `ansible-vault edit` opens the Windows editor.

See [Run Windows programs and scripts](windows-programs.md).

---

## Network

The `localhost` of the tasks reaches the services that listen on the Windows
`localhost`, while the command runs.

Connections to servers go out through Windows, with its routes and VPN. A
connection that the server refuses shows up as reset
(`Connection reset by peer`). See [Network](network.md).

---

## Time

Each command takes a few more seconds to start than on Linux. Access to the
files in Windows folders is also slower than to a Linux disk, which matters in
projects with many files.
