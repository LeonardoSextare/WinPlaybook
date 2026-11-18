# Connection and SSH problems

Start by testing the Windows `ssh` on the same server:

```powershell
ssh deploy@192.168.0.10
```

If the Windows `ssh` also fails, the problem is in the key, the server, or the
network, and not in WinPlaybook.

## Permission denied (publickey)

The server rejected the key.

- Check that the public key is in the `~/.ssh/authorized_keys` file on the
  server.
- Check the user. Without an `ansible_user` in the inventory, Ansible uses
  your Windows user name.
- If the key has a passphrase, it must be in the SSH agent. See
  [Use a key with a passphrase](ssh.md#use-a-key-with-a-passphrase).

---

## Ansible asks for the passphrase or hangs

Ansible doesn't answer the passphrase prompt. Add the key to the Windows SSH
agent and check that Ansible sees it:

```powershell
Invoke-WinPlaybook ssh-add -l
```

If the output says that there's no agent, the Windows `ssh-agent` service is
stopped. See [Use a key with a passphrase](ssh.md#use-a-key-with-a-passphrase).

---

## Host key verification failed

The server isn't in `known_hosts`, or its key changed. Connect once with the
Windows `ssh` and accept the key. Ansible uses the same `known_hosts` file.

If the server was reinstalled, remove the old key:

```powershell
ssh-keygen -R 192.168.0.10
```

---

## Connection timed out or No route to host

The WinPlaybook distribution can't reach the server.

- On a VPN, check that the Windows `ssh` reaches the server. Some VPNs don't
  let WSL traffic through. In that case, see the
  [WSL troubleshooting](https://learn.microsoft.com/windows/wsl/troubleshooting).
- For a name that only the company DNS knows, test with the IP address.
