# What WinPlaybook changes on the system

Everything that WinPlaybook creates or changes, and what happens to each item
when you uninstall it. `%LOCALAPPDATA%` is `C:\Users\<user>\AppData\Local`.

## Installation

| Item                                | Where                                                   | On uninstall                       |
| ----------------------------------- | ------------------------------------------------------- | ---------------------------------- |
| `WinPlaybook` WSL distribution      | `%LOCALAPPDATA%\WinPlaybook\distro`                     | Deleted                            |
| Ansible commands                    | `%LOCALAPPDATA%\WinPlaybook\bin`, or the `-Path` folder | Deleted                            |
| User `PATH` entry                   | The commands folder                                     | Removed                            |
| Configuration and new version notice | `%LOCALAPPDATA%\WinPlaybook`                           | Deleted                            |
| Logs                                | `%LOCALAPPDATA%\WinPlaybook\logs`                       | Deleted                            |
| Autocomplete line                   | `profile.ps1` of PowerShell 7 and Windows PowerShell    | Removed; an empty profile is deleted |
| Collections and roles folders       | `C:\Users\<user>\.ansible`                              | Deleted only if empty              |
| `.ssh` folder, when it doesn't exist | `C:\Users\<user>\.ssh`                                 | Deleted only if empty              |

---

## VS Code extension

With `Enable-WinPlaybookVSCodeExtension`:

| Item                      | Where                                                  | On uninstall       |
| ------------------------- | ------------------------------------------------------ | ------------------ |
| Fixed files               | `C:\Users\<user>\.vscode\extensions\redhat.ansible-*`  | Originals restored |
| Copy of the original files | Next to each file, with `.winplaybook-original`       | Deleted            |

---

## localhost_windows

With `Enable-WinPlaybookLocalhost`:

| Item                        | Where                             | On uninstall                          |
| --------------------------- | --------------------------------- | ------------------------------------- |
| OpenSSH Server feature      | Windows optional features         | Uninstalled if WinPlaybook installed it |
| `WinPlaybookSshd` service   | Windows services                  | Deleted                               |
| Service configuration       | `C:\ProgramData\WinPlaybook\ssh`  | Deleted                               |

---

## What WinPlaybook doesn't change

- Your WSL distributions.
- The VS Code settings.
- The files in the `.ssh` folder. Only `ssh` writes to it, as it would on
  Windows, such as when it adds a host to `known_hosts`.
- The Windows `sshd` and its configuration.
