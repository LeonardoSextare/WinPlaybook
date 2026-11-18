# Environment

Ansible runs on Linux, but with the Windows environment: the environment
variables, the programs in the `Path`, and, in a project with a
`pyproject.toml` file, the versions that the project declares.

## Environment variables

The terminal variables reach Ansible, with the paths translated. The ones that
Linux needs to set its own way, such as `PATH` and `HOME`, stay out. The list
is in [Environment variables](environment-variables.md).

---

## Windows programs

The `PATH` of the tasks has the distribution programs and, after them, the
ones in the Windows `Path`. A Windows program runs by its name, with or
without the extension, in the order of `Path` and `PATHEXT`, as on Windows.

Some exceptions avoid confusion:

- when a name exists on both sides, such as `git` and `ssh`, the Linux one
  runs, which is the one that Ansible expects;
- the Windows Python and pip only run with the extension (`python.exe`), so
  that Ansible doesn't choose the Windows Python for its modules;
- the WinPlaybook commands themselves stay out.

Arguments that are Linux paths, such as `{{ playbook_dir }}`, reach the
Windows program as Windows paths.

---

## Project scripts

A project script runs by its extension, as on Windows, without the Linux
execute permission: `.ps1` with `powershell.exe`, `.bat` and `.cmd` with
`cmd.exe`, `.exe` directly, and `.py` and `.sh` with the shebang. So a dynamic
inventory or a vault password file in `.ps1` works as on Windows.

---

## Per-project environments

Without a `pyproject.toml` file, the commands use the Ansible that
`Install-WinPlaybook` installed. In a folder with a `pyproject.toml` file that
declares `ansible` or `ansible-core`, they use an environment for that project
only, as `uv run` would.

The environment is on the distribution disk, and not in the project folder,
which doesn't get a `.venv`. See
[Use a per-project environment](project-environment.md).
