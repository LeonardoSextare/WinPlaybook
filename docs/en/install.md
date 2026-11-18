# Install WinPlaybook

Choose one of the two installation methods. The fastest is the PowerShell
Gallery. Neither of them needs administrator permission.

## Requirements

| Requirement | Version                                            |
| ----------- | -------------------------------------------------- |
| Windows     | 10 or 11                                           |
| WSL         | 2, latest version                                  |
| PowerShell  | Windows PowerShell 5.1 or PowerShell 7.4 and later |

---

## PowerShell Gallery

If `Get-ExecutionPolicy` shows `Restricted` or `AllSigned`, allow local
scripts for your user:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Install the module:

=== "PowerShell 7.4 and later"

    ```powershell
    Install-PSResource WinPlaybook -Scope CurrentUser
    ```

=== "Windows PowerShell 5.1"

    ```powershell
    Install-Module WinPlaybook -Scope CurrentUser
    ```

    The first time, Windows PowerShell 5.1 asks to install the NuGet
    provider.

PowerShell asks if you trust the PowerShell Gallery. Confirm to install.

Install Ansible and create its commands on Windows:

```powershell
Install-WinPlaybook
```

The first time, the command creates the `WinPlaybook` WSL distribution, with
Debian, and installs Ansible in it. This takes a few minutes.

Test in the same terminal:

```powershell
ansible --version
```

Terminals and programs that were already open, such as VS Code, find the
commands only after you reopen them.

---

## Source code

This method builds the module on your computer. In addition to the
requirements, you need [Git](https://git-scm.com/) and PowerShell 7.4 or
later. Run all the steps in PowerShell 7.

1. Clone the repository:

    ```powershell
    git clone https://github.com/LeonardoSextare/WinPlaybook.git
    cd WinPlaybook
    ```

2. Install the module in the PowerShell 7 modules folder:

    ```powershell
    ./scripts/Build-PacoteDoModulo.ps1 -Versao 0.0.0 -PastaDeDestino (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules')
    ```

3. Install Ansible and create its commands on Windows:

    ```powershell
    Install-WinPlaybook
    ```

4. Test with `ansible --version`.

After the installation, you can delete the cloned repository.

---

## Choose the Ansible version

`Install-WinPlaybook` installs the latest version of Ansible. To use another
version, or to also install the Python packages that a collection needs, pass
the parameters:

```powershell
Install-WinPlaybook -AnsibleVersion '12.*' -PythonPackage 'boto3', 'netaddr'
```

A tool installed this way, such as `molecule` or `yamllint`, gets a command on
Windows, like the Ansible commands:

```powershell
Install-WinPlaybook -PythonPackage 'molecule', 'yamllint'
yamllint .
```

The next runs of `Install-WinPlaybook` keep these choices. To go back to the
latest version, pass `-AnsibleVersion ''`. To remove the packages, pass
`-PythonPackage @()`.

## Use one environment per project

A project can pin its own version of Ansible and of its Python packages with a
[uv](https://docs.astral.sh/uv/) `pyproject.toml` that has `ansible` or
`ansible-core` in its dependencies:

```toml
[project]
name = "infra"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["ansible-core==2.19.*", "ansible-lint", "boto3"]
```

In the project folder, or in a subfolder, the Ansible commands use this
environment, as `uv run` would. The first time, WinPlaybook installs the
packages, and uv writes `uv.lock` to the project. The `Install-WinPlaybook`
installation is left out: a command that the project doesn't declare, such as
`molecule` in this example, doesn't work in this project. The
environment is on the distribution disk, and the project folder doesn't get a
`.venv`.

A tool that the project declares, such as `yamllint`, gets a command on
Windows after the first WinPlaybook command in the project folder.

## Use autocomplete in PowerShell

After the installation, in a new PowerShell terminal, the Tab key completes the
options of the Ansible commands, such as `ansible-playbook --che` to
`--check`, and the subcommands, such as `ansible-galaxy co` to `collection`.
Paths are still completed as in any command. For this, `Install-WinPlaybook`
adds a line to the PowerShell 7 profile and to the Windows PowerShell profile,
and `Uninstall-WinPlaybook` removes it.

In a project with its own environment, autocomplete needs the `argcomplete`
package in the `pyproject.toml` dependencies.

## Use SSH keys with a passphrase

Ansible doesn't answer the passphrase prompt of an SSH key. To use a key with
a passphrase, turn on the Windows SSH agent and add the key to it.
WinPlaybook finds the agent on its own.

1. In PowerShell as an administrator, turn on the agent and make it start
   with Windows:

    ```powershell
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ```

2. In your terminal, add the key and enter the passphrase:

    ```powershell
    ssh-add $env:USERPROFILE\.ssh\id_ed25519
    ```

    The agent keeps the key, so you don't repeat this step after you restart
    Windows.

3. Check that the distribution sees the key:

    ```powershell
    Invoke-WinPlaybook ssh-add -l
    ```

    The output shows the key that you added.

## Update

Update the module with the command for your PowerShell version:

- PowerShell 7.4 and later: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

If you installed from the source code, delete the
`C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder and repeat
steps 1 and 2 with the new code.

Then update Ansible and the commands:

```powershell
Install-WinPlaybook
```

## Uninstall

Delete the distribution and the Ansible commands:

```powershell
Uninstall-WinPlaybook
```

The command asks for confirmation, because it deletes the distribution with
everything in it, such as the collections and roles that `ansible-galaxy`
installed.

Then remove the module:

- PowerShell 7.4 and later: `Uninstall-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Uninstall-Module WinPlaybook`

If you installed from the source code, delete the
`C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder.
