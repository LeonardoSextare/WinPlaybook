# VS Code problems

## The extension wasn't found

!!! failure "Error message"

    ```text
    The VS Code Ansible extension (redhat.ansible) was not found ...
    ```

Install the tested version, as in
[Use VS Code](vscode.md#install-the-tested-version), and run
`Enable-WinPlaybookVSCodeExtension` again.

---

## The extension version wasn't tested

!!! failure "Error message"

    ```text
    The VS Code Ansible extension is at version ..., which WinPlaybook has not tested yet.
    ```

The extension was updated. Go back to the tested version and turn off
automatic updates, as in [Use VS Code](vscode.md).

---

## The fixes stopped working

An update of the extension undoes the fixes. Check the installed version on
the **Extensions** view, go back to the tested version if needed, and run:

```powershell
Enable-WinPlaybookVSCodeExtension
```

---

## The extension doesn't find Ansible

Close all VS Code windows and open them again. A VS Code that you opened
before the installation doesn't see the Ansible commands.

---

## The module documentation doesn't show

VS Code blocks the files on `\\wsl.localhost` without the
`security.allowedUNCHosts` setting. See
[Allow the distribution folder](vscode.md#allow-the-distribution-folder).

---

## The fix wasn't applied

!!! failure "Error message"

    ```text
    Could not fix the VS Code Ansible extension in ...: the file ... does not have the expected code of version ...
    ```

The extension files changed. Reinstall the tested version with the command in
the message, which ends with `--force`, and run
`Enable-WinPlaybookVSCodeExtension` again.
