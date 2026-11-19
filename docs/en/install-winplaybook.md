# Install-WinPlaybook

Installs Ansible in its own WSL distribution and creates its commands on
Windows. Running it again updates Ansible and the commands and keeps the
distribution.

## Syntax

```powershell
Install-WinPlaybook [-Path <string>] [-PowerShell <Desktop | Core>] [-AnsibleVersion <string>] [-PythonPackage <string[]>] [-EnableLocalhost] [-EnableVSCodeExtension] [-PassThru] [-WhatIf] [-Confirm]
```

---

## Parameters

### -Path

The folder where the `WinPlaybook` folder is created. The commands go to
`<Path>\WinPlaybook\bin`.

Default: `%LOCALAPPDATA%\WinPlaybook\bin`.

### -PowerShell

The PowerShell that the `.exe` commands open: `Desktop`, Windows PowerShell
5.1, which opens faster, or `Core`, PowerShell 7.

Default: the one from the previous installation or, in the first one, the
PowerShell that runs the command.

### -AnsibleVersion

The version of the `ansible` package, such as `13.0.0` or `13.*`. An empty
version (`''`) goes back to the latest one.

Default: the one from the previous installation or, without a choice, the
latest one.

### -PythonPackage

The Python packages to install with Ansible, in pip format, such as `boto3`
or `netaddr>=1.0`. The commands of these packages get a command on Windows. An
empty list (`@()`) removes the packages.

Default: the ones from the previous installation.

### -EnableLocalhost

Turns on `localhost_windows` without asking. Without it, the installation asks
before it starts, in an interactive terminal, and keeps the answer if you
decline.

### -EnableVSCodeExtension

Fixes the VS Code Ansible extension without asking. Without it, the installation
asks before it starts, when the extension is installed.

### -PassThru

Returns an object with the commands folder (`Folder`), the distribution
(`Distribution`), and the commands (`Commands`). Without it, the installation
only shows the result in the console.

---

## Examples

```powershell
Install-WinPlaybook
```

```powershell
Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'
```

```powershell
Install-WinPlaybook -Path 'C:\Tools' -PowerShell Desktop
```

---

## What it changes

- Creates the `WinPlaybook` WSL distribution, the first time.
- Creates the commands in `<Path>\WinPlaybook\bin` and adds the folder to the
  user `PATH`.
- Creates the `.ansible\collections` and `.ansible\roles` folders and, when it
  doesn't exist, the `.ssh` folder, in your profile.
- Adds the autocomplete line to the PowerShell profiles.
- Turns on `localhost_windows` and fixes the VS Code Ansible extension, when
  those are the choices.

See [What WinPlaybook changes on the system](system-changes.md).
