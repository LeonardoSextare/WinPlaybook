# WinPlaybook

Use Ansible on Windows as if it were installed locally.

WinPlaybook runs the Ansible command-line tools inside a Linux container and
puts `ansible-playbook`, `ansible-lint`, and the other Ansible commands on your
Windows `PATH`, where your terminal and tools like the VS Code Ansible extension
can use them.

> **Status:** early development. Nothing is released yet.

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 or PowerShell 7
- Docker Desktop

## License

[MIT](LICENSE)
