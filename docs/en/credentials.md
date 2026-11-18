# Credentials

WinPlaybook doesn't store credentials. It takes to Ansible the ones that you
already have on Windows: the SSH keys, the Git sign-in, and the certificates.

## SSH

The Windows `.ssh` folder, in `C:\Users\<user>\.ssh`, is the distribution
`~/.ssh`. The Ansible `ssh` uses the same keys, the same `known_hosts`, and
the same `config`, without copies. Inside the distribution, the folder shows
the permissions that `ssh` requires, without changing the permissions of the
files on Windows.

- New hosts go to `known_hosts` without a hash, as the Windows `ssh` writes
  them, so the file stays in one format. To write them with a hash on both
  sides, use `HashKnownHosts yes` in `config`.
- Without a user in the inventory or in `config`, the connection uses your
  Windows user name.
- `config` can have Windows paths. `ssh` uses a translated copy of it, made
  again for each command, and the Windows file stays as it is.

### The SSH agent

When the Windows SSH agent is on, the Ansible `ssh` uses the keys in it, and a
key with a passphrase works without asking for the passphrase. Linux can't
reach the Windows agent directly, so for each command WinPlaybook opens a link
between the two, which closes when the command ends.

---

## Git

The distribution Git uses your Windows `.gitconfig` file, with the same user
and the same aliases. The sign-in goes through the Windows Git Credential
Manager, so `ansible-galaxy` and the `git` module reach the private
repositories that you already access, without a new sign-in.

---

## Certificates

Ansible trusts the Windows root certificates, in addition to the Debian ones.
On a network that inspects TLS, or with an internal certificate authority
installed on Windows, `ansible-galaxy`, the `uri` and `get_url` modules, `git`,
and `pip` work as on Windows.

---

## localhost_windows

The key that `localhost_windows` uses is on the distribution disk, and not in
your `.ssh` folder. The `WinPlaybookSshd` service only accepts this key,
without a password, and only for your user.
