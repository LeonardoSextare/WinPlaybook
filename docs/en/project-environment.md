# Use a per-project environment

A project can pin its own version of Ansible and of the Python packages with a
[uv](https://docs.astral.sh/uv/) `pyproject.toml`. This way, each project uses
the versions it declares, without affecting the others.

## Declare the environment

Create a `pyproject.toml` in the project root, with `ansible` or
`ansible-core` in the dependencies:

```toml
[project]
name = "infra"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["ansible-core==2.19.*", "ansible-lint", "boto3"]
```

!!! success "Like uv run"

    In the project folder, or in a subfolder, the Ansible commands use this
    environment, as `uv run` would. The first time, WinPlaybook installs the
    packages, and uv writes `uv.lock` to the project. Commit both files.

---

## What changes inside the project

- Only the commands that the project declares work. A tool that you installed
  with `Install-WinPlaybook -PythonPackage`, such as `molecule`, doesn't work
  in a project that doesn't declare it.
- A tool that the project declares, such as `yamllint`, gets a command on
  Windows after the first WinPlaybook command in the project folder.
- The environment is on the distribution disk. The project folder doesn't get
  a `.venv`.
- For [autocomplete](autocomplete.md) to work, add the `argcomplete` package
  to the dependencies.
