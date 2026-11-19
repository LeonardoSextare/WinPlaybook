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

## OpenSSH wasn't downloaded

!!! failure "Error message"

    ```text
    Could not download OpenSSH from https://github.com/PowerShell/Win32-OpenSSH/...
    ```

WinPlaybook downloads OpenSSH from GitHub. Check that Windows can reach the
internet and that the network, or the company proxy, allows `github.com`.
Then run `Enable-WinPlaybookLocalhost` again.

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
