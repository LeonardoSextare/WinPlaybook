# Disable-WinPlaybookLocalhost

Turns off `localhost_windows` and undoes what `Enable-WinPlaybookLocalhost`
did. When `localhost_windows` is off, nothing changes.

## Syntax

```powershell
Disable-WinPlaybookLocalhost [-WhatIf] [-Confirm]
```

---

## Examples

```powershell
Disable-WinPlaybookLocalhost
```

---

## What it changes

- Deletes the `WinPlaybookSshd` service and the
  `C:\ProgramData\WinPlaybook\ssh` folder.
- Uninstalls OpenSSH Server, if WinPlaybook installed it.

Needs an administrator. `Uninstall-WinPlaybook` also turns off
`localhost_windows`.
