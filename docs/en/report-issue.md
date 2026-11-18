# Report a problem

Open an [issue on GitHub](https://github.com/LeonardoSextare/WinPlaybook/issues/new)
with what happened. The more of the information below the issue has, the
faster the problem gets solved.

## What to send

1. The command that you ran and the full output, with the error message.

2. The versions:

    ```powershell
    Get-Module WinPlaybook -ListAvailable | Select-Object Version
    $PSVersionTable.PSVersion
    wsl --version
    ansible --version
    ```

3. The command log, at the `debug` level. Run the command again like this:

    ```powershell
    $env:WINPLAYBOOK_LOG = 'debug'
    ansible-playbook site.yml
    ```

    And attach the log lines from that moment. See [Read the logs](logs.md).

4. If the problem happens in a playbook, a minimal example that reproduces it.

---

## Before you send it

!!! warning "Sensitive data"

    - Remove passwords, tokens, and internal names that you can't publish from
      the log and the output. At the `debug` level, the command arguments go to
      the log.
    - Check whether the problem is already in the
      [open issues](https://github.com/LeonardoSextare/WinPlaybook/issues).
