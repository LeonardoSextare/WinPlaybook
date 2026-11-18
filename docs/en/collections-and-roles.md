# Install collections and roles

`ansible-galaxy` works as it does on Linux. The difference is where the
collections and the roles go: to your Windows profile, as with Ansible
installed on Windows.

| What        | Where it goes                               |
| ----------- | ------------------------------------------- |
| Collections | `C:\Users\<user>\.ansible\collections`      |
| Roles       | `C:\Users\<user>\.ansible\roles`            |

## Install a collection

```powershell
ansible-galaxy collection install community.general
```

---

## Install the dependencies of a project

List the collections and the roles in a `requirements.yml` file:

```yaml
collections:
  - name: community.general
  - name: ansible.posix
roles:
  - name: geerlingguy.docker
```

And install them:

```powershell
ansible-galaxy install -r requirements.yml
```

---

## Install from a private Git repository

!!! tip "Private repositories"

    `ansible-galaxy` uses your Git sign-in on Windows. If you already clone the
    repository on Windows, it works here too:

```yaml
collections:
  - name: https://github.com/my-company/infra-collection.git
    type: git
    version: main
```

See [Use private Git repositories](git.md).

---

## Use a project folder

To keep the collections with the project, set the folder in its
`ansible.cfg` file. Relative paths and Windows paths work:

```ini
[defaults]
collections_path = ./collections
roles_path = ./roles;C:\shared-roles
```
