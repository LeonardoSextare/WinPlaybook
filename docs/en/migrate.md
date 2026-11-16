# Migrate from the Docker version

Up to version 0.2, WinPlaybook ran Ansible in a Docker Desktop container.
This page shows how to move to the WSL version, which has other commands and stores
the collections in another place. Before you start, check the
[requirements](install.md#requirements).

## Update the module

Update the module with the command for your PowerShell version:

- PowerShell 7.4 and later: `Update-PSResource WinPlaybook`
- Windows PowerShell 5.1: `Update-Module WinPlaybook`

If you installed from the source code, delete the
`C:\Users\<user>\Documents\PowerShell\Modules\WinPlaybook` folder, install
the module as described in [Source code](install.md#source-code), and delete
the variable that pointed to the local image:

```powershell
[Environment]::SetEnvironmentVariable('WINPLAYBOOK_IMAGE', $null, 'User')
```

## Install Ansible

`Install-WinPlaybook` replaces `Install-WinPlaybookShim`. It creates the WSL
distribution, installs Ansible, and replaces the old commands with the new
ones:

```powershell
Install-WinPlaybook
```

If you chose the folder of the commands with `-Path` in the previous version,
pass the same `-Path` again. Without it, the commands go to the default
folder, and the old folder is deleted.

To uninstall, `Uninstall-WinPlaybook` replaces `Uninstall-WinPlaybookShim`.

## Install the collections and roles again

The Docker version stored the collections and roles in
`C:\Users\<user>\.ansible`. The WSL version stores them in the distribution,
so install the ones that you use again, for example:

```powershell
ansible-galaxy collection install -r requirements.yml
```

Then, if no other program uses the `C:\Users\<user>\.ansible` folder, you can
delete it.

## Copy the user .ansible.cfg file

The Docker version read `C:\Users\<user>\.ansible.cfg`. The WSL version reads
the `.ansible.cfg` file of the distribution user. If you have this file, copy
it to the distribution:

```powershell
Invoke-WinPlaybook cp "$HOME\.ansible.cfg" /home/winplaybook/.ansible.cfg
```

The `ansible.cfg` files of your projects keep working without changes.

## Remove Docker

WinPlaybook doesn't use Docker Desktop anymore. Delete the old image:

```powershell
docker image rm ghcr.io/leonardosextare/winplaybook:0
```

If you installed from the source code, also delete the local image with
`docker image rm winplaybook:local`. If you don't use Docker Desktop for
anything else, you can uninstall it.
