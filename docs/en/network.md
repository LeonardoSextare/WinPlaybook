# Network

The WinPlaybook distribution has its own network, separate from the Windows
one. While a command runs, WinPlaybook turns on a bridge between the two, and
Ansible reaches what Windows reaches.

## Servers

The Ansible TCP connections, such as SSH, WinRM, and HTTPS, go out through
Windows. Windows makes the connection, so its routes, VPN, and firewall apply,
and Ansible reaches the same servers as PowerShell. This includes Hyper-V
virtual machines on the Default Switch, which the WSL network alone doesn't
reach.

!!! info "How a refused connection shows up"

    When the server refuses the connection, Ansible sees the connection
    reset (`Connection reset by peer`), and not refused
    (`Connection refused`). A server that doesn't answer still times out.

## localhost

On Linux, the `localhost` of a task is the Ansible computer itself. With
WinPlaybook, that computer is the distribution, and a service that you run on
Windows, such as an API in development or a Docker Desktop container, wouldn't
be there.

So, while a command runs, WinPlaybook turns on a bridge: a connection to the
distribution `localhost` that nothing answers there reaches the Windows
`localhost`. This way, a `wait_for` or a `uri` task for `localhost:8080`
reaches the Windows service.

!!! info "Bridge rules"

    - A port that the distribution listens on stays in the distribution.
    - A port that's closed on Windows still refuses the connection.
    - The bridge only exists while a WinPlaybook command runs.
    - Several commands at once, such as the one from VS Code and the one from
      the terminal, share the bridge, and each connection lasts while the
      command that opened it runs.

---

## localhost_windows

`localhost_windows` uses this bridge. Ansible connects over SSH to
`127.0.0.1`, port `47022`, and the bridge takes the connection to the Windows
`WinPlaybookSshd` service, which only listens on `127.0.0.1`, so the port
isn't reachable from the network. See
[Configure Windows itself](localhost-windows.md).

---

## Proxy

The Windows `HTTPS_PROXY`, `HTTP_PROXY`, and `NO_PROXY` variables reach the
commands like the other environment variables. See
[Environment variables](environment-variables.md).
