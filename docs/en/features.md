# WinPlaybook features

WinPlaybook lets Ansible see your Windows computer. Each feature below removes
a difference between running Ansible on Windows and running it on Linux.

<div class="grid cards" markdown>

-   :lucide-terminal: **Commands on Windows**

    ---

    `ansible-playbook`, `ansible-galaxy`, `ansible-lint`, and the other
    commands are in `PATH`. The terminal, scripts, and any program call these
    commands like any other one.

-   :lucide-folder-tree: **Windows paths**

    ---

    `.\playbooks\site.yml` and `C:\infra\hosts.yml` work in the arguments,
    in playbooks, in inventories, and in `ansible.cfg`.

    [:lucide-arrow-right: Paths between Windows and Linux](paths.md)

-   :lucide-key-round: **Your SSH keys**

    ---

    The Windows `.ssh` folder and SSH agent, with the keys, `known_hosts`,
    and `config` that you already have.

    [:lucide-arrow-right: Connect to servers over SSH](ssh.md)

-   :lucide-git-branch: **Your Git sign-in**

    ---

    `ansible-galaxy` and the `git` module use Git Credential Manager and
    reach the private repositories that you already access.

    [:lucide-arrow-right: Use private Git repositories](git.md)

-   :lucide-shield-check: **Your company certificates**

    ---

    Ansible trusts the Windows root certificates. On a network that inspects
    the traffic, downloads work as on Windows.

    [:lucide-arrow-right: Credentials](credentials.md#certificates)

-   :lucide-app-window: **Windows programs and scripts**

    ---

    Tasks call the programs in `Path`, and the project `.ps1` and `.bat`
    files run as on Windows.

    [:lucide-arrow-right: Run Windows programs and scripts](windows-programs.md)

-   :lucide-network: **The Windows network**

    ---

    Connections go out through Windows, with its VPN, routes, and Hyper-V
    virtual machines, and a service on the Windows `localhost`, such as a
    Docker Desktop container, answers on the `localhost` of the tasks.

    [:lucide-arrow-right: Network](network.md)

-   :lucide-monitor-cog: **Your computer as a host**

    ---

    With `localhost_windows`, playbooks configure Windows itself, with the
    `ansible.windows` modules.

    [:lucide-arrow-right: Configure Windows itself](localhost-windows.md)

-   :lucide-package: **A per-project environment**

    ---

    Each project pins the version of Ansible and of the Python packages in a
    `pyproject.toml` file.

    [:lucide-arrow-right: Use a per-project environment](project-environment.md)

-   :lucide-code: **VS Code**

    ---

    The Ansible extension completes, documents, and validates playbooks.

    [:lucide-arrow-right: Use VS Code](vscode.md)

-   :lucide-keyboard: **Autocomplete**

    ---

    The ++tab++ key completes the options of the Ansible commands in
    PowerShell.

    [:lucide-arrow-right: Use autocomplete](autocomplete.md)

-   :lucide-bell-ring: **Notices and logs**

    ---

    A new version notice and a log of each command, with the time of each
    step.

    [:lucide-arrow-right: Read the logs](logs.md)

</div>
