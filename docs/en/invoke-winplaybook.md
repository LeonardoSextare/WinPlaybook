# Invoke-WinPlaybook

Runs a command in the WinPlaybook distribution, from the current folder, with
the same conversions as the Ansible commands. The Ansible commands on Windows,
such as `ansible-playbook`, call `Invoke-WinPlaybook` behind the scenes.

## Syntax

```powershell
Invoke-WinPlaybook <command> [<arguments>]
```

---

## Parameters

### command

The command that runs in the distribution, such as `ansible-playbook` or
`ssh-add`.

### arguments

The command arguments. They reach the command as PowerShell passed them,
without a shell interpreting them. Windows paths become their paths in the
distribution.

---

## Input

What comes through the pipeline goes to the standard input of the command, in
UTF-8.

---

## Output

The command output. The exit code goes to `$LASTEXITCODE`.

---

## Examples

```powershell
Invoke-WinPlaybook ansible-playbook -i inventory.yml site.yml
```

```powershell
'secret' | Invoke-WinPlaybook ansible-vault encrypt_string --stdin-name password
```

```powershell
Invoke-WinPlaybook ssh-add -l
```
