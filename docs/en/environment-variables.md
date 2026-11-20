# Environment variables

## WinPlaybook variables

| Variable                   | Values                          | Default | Effect                                                    |
| -------------------------- | ------------------------------- | ------- | --------------------------------------------------------- |
| `WINPLAYBOOK_LOG`          | `off`, `error`, `info`, `debug` | `info`  | The log detail. See [Read the logs](logs.md).             |
| `WINPLAYBOOK_UPDATE_CHECK` | `off`                           | On      | With `off`, WinPlaybook doesn't tell you about new versions. |

When the [`NO_COLOR`](https://no-color.org/) variable is set, WinPlaybook
notices have no color. Ansible also receives it and turns off the colors of its
output.

---

## Windows variables

The Windows environment variables reach the Ansible commands, such as
`ANSIBLE_CONFIG`, `HTTPS_PROXY`, and the credentials that collections read.
The Windows paths in them become distribution paths, and a list separated by
`;` becomes a list separated by `:`:

| Variable             | On Windows             | For Ansible                 |
| -------------------- | ---------------------- | --------------------------- |
| `ANSIBLE_CONFIG`     | `C:\infra\ansible.cfg` | `/mnt/c/infra/ansible.cfg`  |
| `ANSIBLE_ROLES_PATH` | `C:\roles;D:\roles`    | `/mnt/c/roles:/mnt/d/roles` |
| `HTTPS_PROXY`        | `http://proxy:8080`    | `http://proxy:8080`         |

Some variables don't pass, because Linux sets its own:

- `PATH`, `HOME`, `TEMP`, and `LANG`;
- the Python ones, such as `PYTHONPATH`;
- `SSH_AUTH_SOCK`.

A variable that's already in
[`WSLENV`](https://learn.microsoft.com/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv)
arrives the way `WSLENV` defines.

---

## Certificates

Ansible trusts the Windows root certificates. If you set `SSL_CERT_FILE`,
`REQUESTS_CA_BUNDLE`, `CURL_CA_BUNDLE`, or `GIT_SSL_CAINFO` on Windows, Ansible
uses your file.

---

## Editor

`ansible-vault create` and `ansible-vault edit` open the editor in the Windows
`EDITOR` variable, such as `code --wait`. Without it, they open Notepad.
