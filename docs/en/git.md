# Use private Git repositories

Ansible uses your Windows Git: the same `.gitconfig` file, the same user, and
the same sign-in. If you already clone a private repository on Windows,
`ansible-galaxy` and the `ansible.builtin.git` module clone it too.

## Requirements

| Requirement                                         | Version |
| --------------------------------------------------- | ------- |
| [Git for Windows](https://git-scm.com/download/win) | Latest  |

Git for Windows comes with Git Credential Manager, which stores your sign-in.

---

## Sign in

Clone any private repository on Windows once. Git Credential Manager opens
the browser to sign in and stores the credential:

```powershell
git clone https://github.com/my-company/infra-collection.git
```

After that, Ansible uses the same credential and doesn't ask for anything.

---

## Use it in Ansible

In a task that runs on `localhost`:

```yaml
- name: Download the application code to the project folder
  ansible.builtin.git:
    repo: https://github.com/my-company/app.git
    dest: '{{ playbook_dir }}/app'
  delegate_to: localhost
```

!!! note "Only on your computer"

    The sign-in only works on your computer. A server that clones the repository
    needs its own credential, as on Linux.

In a `requirements.yml` file, see
[Install collections and roles](collections-and-roles.md#install-from-a-private-git-repository).

---

## Repositories over SSH

A repository with a `git@...` address uses the keys in your `.ssh` folder. See
[Connect to servers over SSH](ssh.md).
