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
  `C:\ProgramData\WinPlaybook\ssh` and `C:\ProgramData\WinPlaybook\openssh`
  folders.

Needs an administrator. `Uninstall-WinPlaybook` also turns off
`localhost_windows`.
