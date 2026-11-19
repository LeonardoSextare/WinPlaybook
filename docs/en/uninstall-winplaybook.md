# Uninstall-WinPlaybook

Undoes everything that WinPlaybook changed on the system and deletes the
`WinPlaybook` WSL distribution, with everything in it.

## Syntax

```powershell
Uninstall-WinPlaybook [-WhatIf] [-Confirm]
```

---

## Parameters

### -Confirm

In an interactive terminal, the command asks for confirmation, with no as the
default. `-Confirm:$false` skips the question.

### -WhatIf

Shows what the command would do, without changing anything.

---

## Examples

```powershell
Uninstall-WinPlaybook
```

```powershell
Uninstall-WinPlaybook -Confirm:$false
```

---

## What it changes

- Turns off `localhost_windows`, if it's on.
- Undoes the fixes to the VS Code Ansible extension.
- Deletes the distribution, the commands, the configuration, and the logs.
- Removes the commands folder from `PATH` and the autocomplete line from the
  PowerShell profiles.
- Deletes the `.ansible\collections`, `.ansible\roles`, and `.ssh` folders of
  the profile only if they're empty.

The module stays installed. See [Uninstall WinPlaybook](uninstall.md).
