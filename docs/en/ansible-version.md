# Choose the Ansible version

`Install-WinPlaybook` installs the latest version of Ansible. This page shows
how to change the version and install Python packages with it. To pin the
version of one project only, see
[Use a per-project environment](project-environment.md).

## Change the version

```powershell
Install-WinPlaybook -AnsibleVersion '12.*'
```

To go back to the latest version:

```powershell
Install-WinPlaybook -AnsibleVersion ''
```

---

## Install Python packages

Some collections need Python packages, such as `boto3` for AWS:

```powershell
Install-WinPlaybook -PythonPackage 'boto3', 'netaddr'
```

A tool installed this way, such as `molecule` or `yamllint`, gets a command on
Windows, like the Ansible commands:

```powershell
Install-WinPlaybook -PythonPackage 'molecule', 'yamllint'
yamllint .
```

To remove the packages:

```powershell
Install-WinPlaybook -PythonPackage @()
```

The next runs of `Install-WinPlaybook`, including the ones from
`Update-WinPlaybook`, keep the chosen version and packages.
