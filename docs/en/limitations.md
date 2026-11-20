# Known limitations

These are the differences that WinPlaybook can't hide yet. If one of them gets
in your way, [tell us](report-issue.md). It helps us set the priorities.

## Start time

Each command goes through PowerShell and WSL before Ansible starts. This adds
a little over one second to each command, compared with Ansible running
directly on Linux. The time is almost fixed: in a long playbook, the
difference barely shows, but in `ansible --version` it's most of the time.

The first command after you start Windows takes a few more seconds, because
WSL needs to start the distribution.

---

## Files in Windows folders

Ansible reads the files on Windows drives through WSL, which is slower than
reading from the distribution disk. This matters in projects with thousands of
files, such as a large roles folder or a `synchronize` of a whole folder.

---

## The localhost bridge

The Windows `localhost` only answers in the tasks while a WinPlaybook command
runs. A process that you leave running in the background in the distribution
loses the bridge when the command ends.

The list of Windows ports is updated every second. A service that you started
on Windows less than a second before the command might not answer the first
connection.

---

## VS Code extension

The fixes apply to one tested version of the Ansible extension. An update of
the extension undoes the fixes until WinPlaybook tests the new version. See
[Use VS Code](vscode.md).
