# Your first playbook

In this tutorial, you write a playbook that configures your own Windows
computer: it creates a folder in your profile, writes a file in it, and shows
the Windows version. At the end, you run the same playbook again and see that
Ansible doesn't repeat what's already done.

!!! info "Before you start"

    You need WinPlaybook [installed](install.md).

## 1. Turn on localhost_windows

`localhost_windows` is the host that represents your Windows computer. If you
didn't turn it on during the installation, turn it on now:

```powershell
Enable-WinPlaybookLocalhost
```

!!! note "Administrator"

    Windows asks for administrator approval. The first time, the command can take
    a few minutes.

---

## 2. Create the project folder

```powershell
mkdir $HOME\first-playbook
cd $HOME\first-playbook
```

---

## 3. Write the playbook

Open a new file in Notepad:

```powershell
notepad site.yml
```

Confirm that you want to create the file, paste the content below, and save:

```yaml
- name: My first playbook on Windows
  hosts: localhost_windows
  tasks:
    - name: Create the hello-ansible folder in my profile
      ansible.windows.win_file:
        path: '{{ ansible_facts.user_dir }}\hello-ansible'
        state: directory

    - name: Write a file in the folder
      ansible.windows.win_copy:
        dest: '{{ ansible_facts.user_dir }}\hello-ansible\readme.txt'
        content: Ansible created this file.

    - name: Show the Windows version
      ansible.builtin.debug:
        msg: 'I configured {{ ansible_facts.os_name }}'
```

---

## 4. Run the playbook

```powershell
ansible-playbook site.yml
```

Ansible connects to your Windows computer, creates the folder and the file,
and shows the Windows version. The recap at the end shows what changed:

```text
PLAY RECAP *********************************************************************
localhost_windows          : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Open the folder and look at the file:

```powershell
explorer $HOME\hello-ansible
```

---

## 5. Run it again

```powershell
ansible-playbook site.yml
```

!!! success "Idempotence"

    This time, the recap shows `changed=0`. The folder and the file are already
    the way the playbook describes, and Ansible only does what's missing.

---

## Next steps

- Open the project in VS Code with the [Ansible extension](vscode.md).
- Configure [servers over SSH](ssh.md).
- See the [WinPlaybook features](features.md).
- The Windows modules are in the documentation of the
  [ansible.windows collection](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html).
