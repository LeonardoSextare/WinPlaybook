# Why WinPlaybook

Ansible [doesn't support Windows as a control node](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html#control-node-requirements),
the machine that runs the playbooks. But if you work on Windows, you already
have an environment set up: PowerShell with your modules and profile, your
editor with the extensions that you use, your shortcuts, and your everyday
scripts. To use Ansible, you have to leave that environment.

## The common alternatives

The common ways to use Ansible on Windows are WSL, a virtual machine, or a
Linux server, often accessed through the
[WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)
and
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extensions for VS Code. They all work: Ansible runs, and so do the playbooks.

The cost is the same for all of them: Ansible runs on another system, and you
start to work on that system. Your Windows setup doesn't come with you. You set up your
environment again on the other side and get used to another terminal, another
shell, and another way of working. Even the VS Code extensions don't avoid
this: the editor window stays on Windows, but the terminal, the files, and some
of the extensions run on Linux, and you have to install those extensions
again.

## Why a container

WinPlaybook adds the Ansible commands to your Windows `PATH` and runs each one
in a disposable container that Docker creates when the command starts and
removes when it ends. The `ansible-playbook` command is available to the
terminal and to any program that runs on Windows, like a native command, and
you keep working on Windows.

[Docker Desktop](https://docs.docker.com/desktop/) already runs Linux without
extra setup. The WinPlaybook image includes Ansible, `ansible-lint`, and the
libraries to manage Windows machines. You don't install Python or Ansible on
Windows, and everyone who uses the same image has the same tool versions.

In exchange, Docker Desktop must be running, and each command takes a few
more seconds to start. These and other limitations are in
[How it works](how-it-works.md#limitations).
