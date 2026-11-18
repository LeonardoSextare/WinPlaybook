# Known limitations

!!! info "Version 0"

    WinPlaybook is at version 0. What's below is known and has an open or planned
    issue. When a limitation gets in your way,
    [tell us in the issue](report-issue.md): it helps decide the order.

## Start time

Each command goes through WSL, and the `.exe` commands also open PowerShell.
This adds a few seconds to the start of each run, more when the distribution
is stopped. Optimization is the next step of the project, after all the
features are ready.

---

## Files in Windows folders

Access to the files on Windows drives is slower than to the distribution
disk. This matters in projects with many files.

---

## The localhost bridge

The Windows `localhost` only answers in the tasks while a WinPlaybook command
runs. A process that you leave running in the background in the distribution
loses the bridge when the command ends.

---

## VS Code extension

The fixes apply to one tested version of the Ansible extension. An update of
the extension undoes the fixes until WinPlaybook tests the new version.

---

## SSH agent

On some computers, the first request to the Windows SSH agent fails, and the
next command works. The cause hasn't been found yet.
