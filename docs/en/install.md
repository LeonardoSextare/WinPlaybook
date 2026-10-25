# Install WinPlaybook

Choose one of the three installation methods. The fastest is the install
script. None of them needs administrator permission.

## Requirements

| Requirement    | Version                                         |
| -------------- | ----------------------------------------------- |
| Windows        | 10 22H2 or 11 23H2 and later, 64-bit            |
| Docker Desktop | with the WSL 2 backend and Linux containers     |
| PowerShell     | Windows PowerShell 5.1 or PowerShell 7.4 and later |

---

## Install script

Run in PowerShell:

```powershell
irm https://leonardosextare.github.io/WinPlaybook/install.ps1 | iex
```

The first installation can take a few minutes because it downloads the
Ansible image.

Open a new terminal and test:

```powershell
ansible --version
```

To update, run the script again or use the command for your PowerShell version:

- PowerShell 7.4 and later: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

---

## PowerShell Gallery

This method uses the commands of PowerShell itself, without the install script.

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

Create the Ansible commands. The first time, the command downloads the image:

```powershell
Install-WinPlaybookShim
```

Open a new terminal and test with `ansible --version`.

To update, use `Update-PSResource WinPlaybook` in PowerShell 7.4 and later or
`Update-Module WinPlaybook` in Windows PowerShell 5.1.

---

## Source code

This method builds the image and the module on your computer. In addition to
the requirements, you need [Git](https://git-scm.com/) and PowerShell 7.4 or
later. Run all the steps in PowerShell 7.

1. Clone the repository:

    ```powershell
    git clone https://github.com/LeonardoSextare/WinPlaybook.git
    cd WinPlaybook
    ```

2. Build the image and configure WinPlaybook to use it:

    ```powershell
    docker build --tag winplaybook:local image
    [Environment]::SetEnvironmentVariable('WINPLAYBOOK_IMAGE', 'winplaybook:local', 'User')
    $env:WINPLAYBOOK_IMAGE = 'winplaybook:local'
    ```

3. Install the module in the PowerShell 7 modules folder:

    ```powershell
    $modulesFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    ./scripts/Build-ModulePackage.ps1 -Version 0.0.0 -Destination $modulesFolder
    ```

4. Create the Ansible commands:

    ```powershell
    Install-WinPlaybookShim
    ```

5. Open a new terminal and test with `ansible --version`.

After the installation, you can delete the cloned repository.

To update, delete the
`C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder and repeat
the steps with the new code.
