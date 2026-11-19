# Enable-WinPlaybookLocalhost

Turns on `localhost_windows`, the host that lets playbooks configure the
Windows computer itself, with the `ansible.windows` modules.

## Syntax

```powershell
Enable-WinPlaybookLocalhost [-WhatIf] [-Confirm]
```

---

## Examples

```powershell
Enable-WinPlaybookLocalhost
```

---

## Notes

- Needs an administrator. In a PowerShell that isn't an administrator one,
  Windows asks for approval.
- The first time, the command downloads OpenSSH from the official Microsoft
  release on GitHub, a few MB.

---

## What it changes

- Downloads OpenSSH to `C:\ProgramData\WinPlaybook\openssh`, a folder that only
  WinPlaybook uses. Nothing is installed on Windows: the OpenSSH Server feature,
  `ssh-agent`, and the `ssh` client stay as they are.
- Creates the `WinPlaybookSshd` service, with its configuration in
  `C:\ProgramData\WinPlaybook\ssh`. It only listens on `127.0.0.1`, on port
  `47022`, and only accepts the key in the distribution, without a password,
  for your user.
- Creates the key in the distribution.

See [Configure Windows itself](localhost-windows.md) and
[Disable-WinPlaybookLocalhost](disable-winplaybooklocalhost.md).
