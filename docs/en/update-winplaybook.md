# Update-WinPlaybook

Updates the WinPlaybook module from the PowerShell Gallery and runs
`Install-WinPlaybook` from the new version, which updates Ansible and the
commands.

## Syntax

```powershell
Update-WinPlaybook [-WhatIf] [-Confirm]
```

---

## Parameters

### -WhatIf

Shows what the command would do, without changing anything.

---

## Examples

```powershell
Update-WinPlaybook
```

---

## Notes

- The Ansible version and the Python packages that you chose in
  `Install-WinPlaybook` stay the same.
- A module installed from source code doesn't update with this command. See
  [Update WinPlaybook](update.md#installation-from-source-code).
