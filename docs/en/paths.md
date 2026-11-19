# Paths between Windows and Linux

Linux doesn't understand `C:\infra`. The distribution sees the Windows drives
in its own folders, such as `/mnt/c`, and WinPlaybook translates the paths in
both directions. Each path still points to the same file.

## On the way in: what you pass

Before it runs the command, WinPlaybook converts the arguments that are
Windows paths and leaves the others as they are:

- a path with a drive letter goes to the drive folder in `/mnt`;
- a path on a drive created with `subst` goes to its real folder;
- a network path, or a path on a mapped network drive, goes to
  `/mnt/unc/<server>/<share>`, which the distribution mounts with your Windows
  credentials;
- a path on the distribution disk, in `\\wsl.localhost\WinPlaybook\`, becomes
  its Linux path;
- a relative path with `\` uses `/` when it starts with `.\` or `..\`, or when
  its folder exists, even if the file doesn't exist yet.

This also applies after an option with `=` or an `@`, and to the value of a
`key=value` argument, such as those of `-e` and `-a`
(`-e folder=C:\infra\files`).

With the current folder in `C:\infra`, which has the `vars` and `output`
folders:

| Argument                                             | In the distribution                  |
| ---------------------------------------------------- | ------------------------------------ |
| `.\playbooks\site.yml`                               | `./playbooks/site.yml`               |
| `C:\infra\inventory\prod.yml`                        | `/mnt/c/infra/inventory/prod.yml`    |
| `D:\other\hosts.yml`                                 | `/mnt/d/other/hosts.yml`             |
| `\\server\infra\site.yml`                            | `/mnt/unc/server/infra/site.yml`     |
| `--inventory=C:\infra\hosts.yml`                     | `--inventory=/mnt/c/infra/hosts.yml` |
| `@vars\prod.yml`                                     | `@vars/prod.yml`                     |
| `output\report.json`, which doesn't exist yet        | `output/report.json`                 |
| `\\wsl.localhost\WinPlaybook\home\winplaybook\a.yml` | `/home/winplaybook/a.yml`            |
| `~web\d+`                                            | `~web\d+`, not a path                |

---

## Inside the Ansible files

An absolute Windows path also works inside the files: in a variable
(`file: C:\infra\files\data.txt`), in the `src` of a `copy` or `template`
task, in a lookup or `include`, in the inventory, and in the `ansible.cfg`
paths, such as `roles_path`, which can separate several Windows paths with
`;`.

---

## In the environment variables

The paths in environment variables follow the same rules. See
[Environment variables](environment-variables.md).

---

## On the way back: what Ansible shows

The command output shows paths in the Windows format:

- a drive path becomes `C:\infra\site.yml`, and not `/mnt/c/infra/site.yml`;
- in `ansible --version`, `ansible-config`, `ansible-doc`, and
  `ansible-galaxy`, a distribution path becomes
  `\\wsl.localhost\WinPlaybook\...`, which File Explorer opens;
- a list of paths is separated by `;`, as in `Path`;
- inside quotes, as in JSON output or a Python list, the backslashes are
  doubled (`"C:\\infra\\site.yml"`), so the JSON stays valid.

---

## Line endings

A script with a shebang (`#!/bin/sh`) and CRLF line endings, like the ones that
Git for Windows writes by default, runs with `ansible.builtin.script`: Ansible
sends a copy without the CR characters, and the project file stays as it is.
