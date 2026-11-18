# Use VS Code

With the Red Hat Ansible extension, VS Code shows the module documentation,
completes playbooks, and validates them with `ansible-lint`. This page gets
the extension working with WinPlaybook.

## Install the tested version

WinPlaybook fixes the extension so that it works on Windows, and each version
of the extension needs to be tested first. The tested version is 26.11.0:

```powershell
code --install-extension redhat.ansible@26.11.0
```

## Turn off automatic updates for the extension

An update of the extension undoes the fixes. In the **Extensions** view of VS
Code, right-click the **Ansible** extension and clear **Auto Update**.

## Apply the fixes

In PowerShell:

```powershell
Enable-WinPlaybookVSCodeExtension
```

The command shows the fixed version, its folder, and the settings that VS
Code needs.

## Allow the distribution folder

The module documentation is in the WinPlaybook distribution, which VS Code
opens through `\wsl.localhost`. Open the user `settings.json` (**Preferences:
Open User Settings (JSON)**) and add:

```json
"security.allowedUNCHosts": ["wsl.localhost"]
```

Then reload the window (**Developer: Reload Window**).

## Undo the fixes

```powershell
Disable-WinPlaybookVSCodeExtension
```

`Uninstall-WinPlaybook` also undoes the fixes.
