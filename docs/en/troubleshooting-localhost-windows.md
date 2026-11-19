# localhost_windows problems

## The localhost_windows host doesn't exist

!!! failure "Error message"

    ```text
    [WARNING]: Could not match supplied host pattern, ignoring: localhost_windows
    ```

`localhost_windows` is off. Turn it on with:

```powershell
Enable-WinPlaybookLocalhost
```

---

## Windows didn't open the administrator PowerShell

!!! failure "Error message"

    ```text
    Windows did not open the administrator PowerShell that the command needs ...
    ```

The approval window was declined or closed. Run the command again and approve
it. If your account isn't an administrator, ask the person who manages the
computer to run the command for you.

---

## The command failed as administrator

!!! failure "Error message"

    ```text
    The command Enable-WinPlaybookLocalhost -Confirm:$false failed as administrator (exit code 1): ...
    ```

The end of the message has the cause. Fix what it points to and run the command
again. If the cause isn't clear, [open an issue](report-issue.md) with the full
message.

---

## OpenSSH Server wasn't installed

The installation of the feature downloads files from Windows Update. In a
company, Windows can use an update server that doesn't have the feature. Talk
to the team that manages the computers, or install the feature in
**Settings**, **System**, **Optional features**, **OpenSSH Server**, and run
`Enable-WinPlaybookLocalhost` again.

---

## The WinPlaybookSshd service didn't start

!!! failure "Error message"

    ```text
    The WinPlaybookSshd service did not start. ...
    ```

Run `Enable-WinPlaybookLocalhost` again. If the error continues,
[open an issue](report-issue.md) with the full message.

---

## UNREACHABLE when connecting

!!! failure "Error message"

    ```text
    localhost_windows | UNREACHABLE! => ... Connection refused
    ```

Check that the service is running:

```powershell
Get-Service WinPlaybookSshd
```

If it's stopped, start it in PowerShell as an administrator:

```powershell
Start-Service WinPlaybookSshd
```
