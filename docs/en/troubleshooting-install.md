# Installation problems

## WSL isn't installed

!!! failure "Error message"

    ```text
    WSL is not installed. Install it with: wsl --install --no-distribution ...
    ```

In PowerShell as an administrator:

```powershell
wsl --install --no-distribution
```

Restart Windows if it asks you to, and run `Install-WinPlaybook` again.

---

## Virtualization is turned off

`wsl --install` finishes, but `Install-WinPlaybook` fails to create the
distribution, with a WSL message about virtualization or about the Virtual
Machine Platform.

1. In PowerShell as an administrator, turn on the feature:

    ```powershell
    wsl --install --no-distribution
    ```

2. Check that virtualization is on in the BIOS or UEFI of the computer. In
   Task Manager, on the **Performance** tab, **CPU**, the **Virtualization**
   field shows **Enabled**.

3. Restart Windows and run `Install-WinPlaybook` again.

---

## PowerShell doesn't run scripts

!!! failure "Error message"

    ```text
    ... cannot be loaded because running scripts is disabled on this system.
    ```

Allow local scripts for your user:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

If your company controls this policy, the command doesn't change anything.
Talk to the team that manages the computers.

---

## The distribution wasn't created

!!! failure "Error message"

    ```text
    Could not create the WSL distribution WinPlaybook. Check the internet connection and whether WSL is up to date (wsl --update).
    ```

1. Update WSL:

    ```powershell
    wsl --update
    ```

2. Check that Windows can reach the internet.

3. Run `Install-WinPlaybook` again.

---

## Ansible wasn't installed

!!! failure "Error message"

    ```text
    Could not install Ansible in the WSL distribution WinPlaybook. Check the Ansible version, the Python packages and the internet connection ...
    ```

The message ends with the uv answer, which says what failed. Common causes
are:

- an Ansible version that doesn't exist, in `-AnsibleVersion`;
- a package with the wrong name, in `-PythonPackage`;
- no access to PyPI, the Python package repository.

Fix it and run `Install-WinPlaybook` again.

---

## The C# compiler wasn't found

!!! failure "Error message"

    ```text
    The .NET Framework C# compiler is not in ...
    ```

Install [.NET Framework 4.8](https://dotnet.microsoft.com/download/dotnet-framework/net48)
and run `Install-WinPlaybook` again.

---

## The folder already exists

!!! failure "Error message"

    ```text
    The folder ... already exists and wasn't created by WinPlaybook.
    ```

`-Path` points to a `WinPlaybook` folder that doesn't belong to WinPlaybook.
Choose another `-Path` or delete the folder.

---

## The command isn't found after the installation

!!! failure "Error message"

    ```text
    ansible : The term 'ansible' is not recognized ...
    ```

Close and open the terminal. Terminals and programs that you opened before the
installation don't see the new `PATH` folder.
