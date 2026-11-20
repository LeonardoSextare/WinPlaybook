# Update WinPlaybook

Update the module, Ansible, and the commands at once:

```powershell
Update-WinPlaybook
```

The Ansible version and the Python packages that you chose stay the same.

## The new version notice

WinPlaybook tells you when a new version exists, in yellow, the first time you
run one of its commands in the terminal:

```text
WinPlaybook: version 0.20.0 is available (you use 0.19.0). Update with: Update-WinPlaybook
```

It checks the PowerShell Gallery in the background, at most once an hour,
without slowing down the command. A version published after the last check
shows up in the notice within an hour.

To turn off the notice, set the `WINPLAYBOOK_UPDATE_CHECK` environment
variable to `off`:

```powershell
[Environment]::SetEnvironmentVariable('WINPLAYBOOK_UPDATE_CHECK', 'off', 'User')
```

---

## Installation from source code

!!! note "Source code"

    If you installed from source code, delete the
    `C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder, repeat
    steps 1 and 2 of the [installation](install.md#source-code) with the new code,
    and run `Install-WinPlaybook`.
