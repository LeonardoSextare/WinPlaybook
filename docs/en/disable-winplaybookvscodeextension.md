# Disable-WinPlaybookVSCodeExtension

Restores the original files of the VS Code Ansible extension, in all the
versions that `Enable-WinPlaybookVSCodeExtension` fixed. A version without the
fixes stays as it is.

## Syntax

```powershell
Disable-WinPlaybookVSCodeExtension [-WhatIf] [-Confirm]
```

---

## Examples

```powershell
Disable-WinPlaybookVSCodeExtension
```

`Uninstall-WinPlaybook` also undoes the fixes.
