# WinPlaybook

Use Ansible on Windows as if it were installed locally.

WinPlaybook runs the Ansible command-line tools in a WSL distribution and puts
`ansible-playbook`, `ansible-lint`, and the other Ansible commands on your
Windows `PATH`, where your terminal and tools like the VS Code Ansible extension
can use them.

> **Status:** early development. The project is at version 0, so any release
> can bring breaking changes.

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 or PowerShell 7.4 or later
- WSL, with a distribution that has Ansible installed

## License

[MIT](LICENSE)
