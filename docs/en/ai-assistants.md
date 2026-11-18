# Use with AI assistants

AI assistants, such as Claude Code, GitHub Copilot, and Cursor, don't know
WinPlaybook. In an Ansible project on Windows, they often suggest installing
Ansible in WSL, opening a Linux terminal, or replacing Windows paths with
Linux paths. This page shows how to explain WinPlaybook to them.

## Add the instructions to the project

Copy the block below to the instructions file that your assistant reads, in
the project root:

| Assistant      | File                              |
| -------------- | --------------------------------- |
| Several        | `AGENTS.md`                       |
| Claude Code    | `CLAUDE.md`                       |
| GitHub Copilot | `.github/copilot-instructions.md` |

!!! tip "One file for all"

    Many assistants read `AGENTS.md`. In Claude Code, a `CLAUDE.md` file with
    the `@AGENTS.md` line imports the same content.

```markdown
## Ansible with WinPlaybook

This project uses Ansible on Windows through WinPlaybook
(https://leonardosextare.github.io/WinPlaybook/).

- The Ansible commands (`ansible-playbook`, `ansible-galaxy`, `ansible-lint`,
  and the others) run directly in Windows PowerShell. Don't suggest installing
  Ansible in WSL, opening a Linux terminal, or putting `wsl` before the
  commands.
- Windows paths work in arguments, playbooks, inventories, and `ansible.cfg`,
  such as `.\playbooks\site.yml` and `C:\infra\hosts.yml`.
- `localhost` is the control node, a Linux system. The user's Windows computer
  is the `localhost_windows` host, which uses the `ansible.windows` modules.
- Collections and roles are in `C:\Users\<user>\.ansible`. SSH keys are in
  the Windows `.ssh` folder, and the Windows SSH agent works.
- Programs in the Windows `Path` work in `localhost` tasks. When a name exists
  on both systems, such as `git`, the Linux one runs.
- To change the Ansible version in a project, use a uv `pyproject.toml` file
  with `ansible` or `ansible-core` in the dependencies.
- The differences from Ansible on Linux are in
  https://leonardosextare.github.io/WinPlaybook/en/differences/
```

---

## Keep the instructions up to date

The block describes WinPlaybook in this version. After an update with big
changes, check this page and copy the block again.
