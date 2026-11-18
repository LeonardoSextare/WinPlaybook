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

The first time, the command downloads Debian and Ansible, which takes a few
minutes. At the end, it asks whether you want to turn on `localhost_windows`,
which lets playbooks configure Windows itself. To decide later, see
[Configure Windows itself](localhost-windows.md).

Test in the same terminal:

```powershell
ansible --version
```

!!! note "Open terminals"

    Terminals and programs that were already open, such as VS Code, find the
    commands only after you reopen them.

---

## Source code

This method builds the module on your computer. In addition to the
requirements above, you need [Git](https://git-scm.com/) and PowerShell 7.4 or
later. Run all steps in PowerShell 7.

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

## Next step

Run [your first playbook](first-playbook.md).
