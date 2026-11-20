# Read the logs

WinPlaybook writes a log of each command, with the exit code and the time of
each step, and of the installation, with the time of each step and the cause of
a failure. It helps to understand an error and to measure how much WinPlaybook
adds to the Ansible time. This page shows where the logs are and how to choose
the detail.

## Where they are

The logs are in `%LOCALAPPDATA%\WinPlaybook\logs`, one file per day, such as
`winplaybook-2026-11-18.log`. Files older than 7 days are deleted, and
`Uninstall-WinPlaybook` deletes the folder.

```powershell
Get-Content "$env:LOCALAPPDATA\WinPlaybook\logs\winplaybook-$(Get-Date -Format yyyy-MM-dd).log" -Tail 20
```

---

## Choose the detail

The `WINPLAYBOOK_LOG` environment variable chooses the level:

| Level   | What it writes                                                              |
| ------- | --------------------------------------------------------------------------- |
| `off`   | Nothing                                                                     |
| `error` | Only errors                                                                 |
| `info`  | Errors, one line per command, with the time of each step, and the error that Windows gave for a connection that failed (the default) |
| `debug` | Also the folder, the arguments, and the time of each step in the distribution |

For the current PowerShell session:

```powershell
$env:WINPLAYBOOK_LOG = 'debug'
```

!!! warning "Passwords in the log"

    At the `debug` level, the command arguments go to the log. If you pass
    passwords in the arguments, such as in `-e password=...`, go back to `info`
    afterwards.

---

## Attach to an issue

When you open an issue, run the failing command at the `debug` level and attach
the log lines from that moment. The log doesn't keep the values of environment
variables or the content of files.
