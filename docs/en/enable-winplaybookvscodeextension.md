# Enable-WinPlaybookVSCodeExtension

Fixes the VS Code Ansible extension (`redhat.ansible`) so that it works on
Windows with WinPlaybook. The fixes go to the latest installed version of the
extension, as long as WinPlaybook already tested that version.

## Syntax

```powershell
Enable-WinPlaybookVSCodeExtension [-WhatIf] [-Confirm]
```

---

## Output

An object with:

| Property           | Content                                               |
| ------------------ | ----------------------------------------------------- |
| `Version`          | The fixed version of the extension                    |
| `Path`             | The extension folder                                  |
| `RequiredSettings` | What the VS Code `settings.json` file needs to have   |

---

## Examples

```powershell
Enable-WinPlaybookVSCodeExtension
```

---

## What it changes

The extension files, in `C:\Users\<user>\.vscode\extensions`. The original
files are kept next to them, with the `.winplaybook-original` extension. The
command doesn't change the VS Code settings.

See [Use VS Code](vscode.md) and
[Disable-WinPlaybookVSCodeExtension](disable-winplaybookvscodeextension.md).
