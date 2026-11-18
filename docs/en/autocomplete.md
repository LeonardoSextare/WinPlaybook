# Use autocomplete

In PowerShell, the Tab key completes the options of the Ansible commands, such
as `ansible-playbook --che` to `--check`, and the subcommands, such as
`ansible-galaxy co` to `collection`. Paths are still completed as in any
command.

`Install-WinPlaybook` turns on autocomplete in the PowerShell 7 profile and in
the Windows PowerShell profile. It works in every new terminal, without
configuration.

## In a project with its own environment

In a project with [its own environment](project-environment.md), add the
`argcomplete` package to the `pyproject.toml` dependencies:

```toml
dependencies = ["ansible-core==2.19.*", "argcomplete"]
```

---

## In a terminal that was already open

In a terminal that you opened before the installation, turn on autocomplete
right away:

```powershell
Register-WinPlaybookArgumentCompleter
```
