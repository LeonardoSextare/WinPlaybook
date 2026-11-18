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
- The first time, it can take a few minutes, because Windows downloads
  OpenSSH Server.

---

## What it changes

- Installs the OpenSSH Server optional feature, when it's missing.
- Creates the `WinPlaybookSshd` service, with its configuration in
  `C:\ProgramData\WinPlaybook\ssh`. It only listens on `127.0.0.1`, on port
  `47022`, and only accepts the key in the distribution, without a password,
  for your user.
- Creates the key in the distribution.

See [Configure Windows itself](localhost-windows.md) and
[Disable-WinPlaybookLocalhost](disable-winplaybooklocalhost.md).
