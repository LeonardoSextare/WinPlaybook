# Uninstall WinPlaybook

Delete the distribution and the Ansible commands:

```powershell
Uninstall-WinPlaybook
```

!!! warning "Warning"

    The command asks for confirmation, because the distribution is deleted with
    everything in it. The default is no: Enter cancels, without changing anything. If `localhost_windows` is on, Windows also asks for
    administrator approval to turn it off.

Then remove the module:

=== "PowerShell 7.4 and later"

    ```powershell
    Uninstall-PSResource WinPlaybook
    ```

=== "Windows PowerShell 5.1"

    ```powershell
    Uninstall-Module WinPlaybook
    ```

If you installed from source code, delete the
`C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder.

## What stays

WinPlaybook doesn't delete what's yours:

- the collections and the roles in `C:\Users\<user>\.ansible`;
- the `.ssh` folder, when it has files;
- your projects.

The full list of what WinPlaybook creates and deletes is in
[What WinPlaybook changes on the system](system-changes.md).
