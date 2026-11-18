# Problems running commands

## WinPlaybook isn't installed

!!! failure "Error message"

    ```text
    WinPlaybook is not installed. Install it with: Install-WinPlaybook
    ```

The module is installed, but `Install-WinPlaybook` didn't run yet, or
`Uninstall-WinPlaybook` already ran. Run `Install-WinPlaybook`.

---

## The distribution no longer exists

!!! failure "Error message"

    ```text
    The WinPlaybook WSL distribution WinPlaybook no longer exists. Install it again with: Install-WinPlaybook
    ```

The distribution was deleted outside WinPlaybook, such as by
`wsl --unregister`. Run `Install-WinPlaybook`, which creates a new one.

---

## A command is missing in the distribution

!!! failure "Error message"

    ```text
    WinPlaybook: the command ansible-xyz is missing in the WSL distribution. Run Install-WinPlaybook to update the commands.
    ```

The command is left from an earlier installation, or from a package that you
removed from `-PythonPackage`. Run `Install-WinPlaybook`.

In a project with [its own environment](project-environment.md), only the
commands that `pyproject.toml` declares work. Add the package to the
dependencies.

---

## The first command is slow

The first command after Windows starts takes a few more seconds, because WSL
starts the distribution. The next commands start faster. The first command in
a project with [its own environment](project-environment.md) also takes
longer, because it installs the packages.

---

## A drive or a share isn't available

!!! failure "Error message"

    ```text
    Could not access \\server\infra in the WSL distribution. Check that the drive or share is available in Windows and try again.
    ```

Open the folder in File Explorer. If Windows asks for credentials, enter them
and run the command again.

---

## A Windows path doesn't work

WinPlaybook converts the Windows paths in the arguments, in the Ansible files,
and in the environment variables. Text that doesn't look like a path stays as
it is. If a relative path with `\` isn't converted, start it with `.\`:

```powershell
ansible-playbook .\playbooks\site.yml
```

See the rules in [Paths between Windows and Linux](paths.md).

---

## The project ansible.cfg file is ignored

Run the command in the project folder, or in a subfolder of it. Ansible looks
for `ansible.cfg` in the current folder. Without an `ansible.cfg` file in the
project, it uses `C:\Users\<user>\.ansible.cfg`.

Check which file is in use:

```powershell
ansible --version
```

The `config file` line shows the file.

---

## Another error

See [Read the logs](logs.md) and [Report a problem](report-issue.md).
