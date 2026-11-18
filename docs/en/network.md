# Network

The WinPlaybook distribution has its own network, separate from the Windows
one. For servers on the network and on the internet, this doesn't change
anything: Ansible reaches them as Windows does. The difference is in
`localhost`.

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
