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

## Why its own WSL distribution

WinPlaybook adds the Ansible commands to your Windows `PATH` and runs each one
in a WSL distribution that belongs only to WinPlaybook. The `ansible-playbook`
command is available to the terminal and to any program that runs on Windows,
like a native command, and you keep working on Windows. The distribution stays
behind the commands, and you don't need to open a terminal in it.

WSL is a Windows feature and can see the Windows drives. Ansible reads the
playbooks in the folder where they already are, and WinPlaybook converts the
Windows paths in the arguments to the distribution paths. You don't install
Python or Ansible on Windows.

The distribution is separate so that WinPlaybook doesn't change the
distributions that you already have. WinPlaybook sets it up the way Ansible
needs, and `Uninstall-WinPlaybook` deletes all of it.

In exchange, the first installation downloads Debian and Ansible and takes a
few minutes, and each command takes a little longer to start. These and other
limitations are in [How it works](how-it-works.md#limitations).
