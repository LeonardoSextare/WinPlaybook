# Variáveis de ambiente

## Variáveis do WinPlaybook

| Variável                   | Valores                            | Padrão | Efeito                                                              |
| -------------------------- | ---------------------------------- | ------ | ------------------------------------------------------------------- |
| `WINPLAYBOOK_LOG`          | `off`, `error`, `info`, `debug`    | `info` | O detalhe dos logs. Veja [Consultar os logs](logs.md).              |
| `WINPLAYBOOK_UPDATE_CHECK` | `off`                              | Ligado | Com `off`, o WinPlaybook não avisa sobre versões novas.             |

Com a variável [`NO_COLOR`](https://no-color.org/) definida, os avisos do
WinPlaybook saem sem cor. Ela também chega ao Ansible, que desliga as cores da
saída.

---

## Variáveis do Windows

O Ansible recebe as variáveis de ambiente do Windows, como o `ANSIBLE_CONFIG`,
o `HTTPS_PROXY` e as credenciais usadas pelas _collections_. Os caminhos do
Windows que aparecem nelas são convertidos para o formato da distribuição, e
as listas separadas por `;` passam a ser separadas por `:`:

| Variável             | No Windows             | Para o Ansible              |
| -------------------- | ---------------------- | --------------------------- |
| `ANSIBLE_CONFIG`     | `C:\infra\ansible.cfg` | `/mnt/c/infra/ansible.cfg`  |
| `ANSIBLE_ROLES_PATH` | `C:\roles;D:\roles`    | `/mnt/c/roles:/mnt/d/roles` |
| `HTTPS_PROXY`        | `http://proxy:8080`    | `http://proxy:8080`         |

Algumas variáveis não são repassadas, porque o Linux usa valores próprios para
elas:

- `PATH`, `HOME`, `TEMP` e `LANG`;
- as variáveis do Python, como o `PYTHONPATH`;
- o `SSH_AUTH_SOCK`.

Uma variável que já está no
[`WSLENV`](https://learn.microsoft.com/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv)
é repassada da forma definida no `WSLENV`.

---

## Certificados

O Ansible confia nos certificados raiz do Windows. Se você define o
`SSL_CERT_FILE`, o `REQUESTS_CA_BUNDLE`, o `CURL_CA_BUNDLE` ou o
`GIT_SSL_CAINFO` no Windows, o Ansible usa o arquivo indicado.

---

## Editor

O `ansible-vault create` e o `ansible-vault edit` abrem o editor
definido na variável `EDITOR` do Windows, como `code --wait`. Sem essa
variável, eles abrem o Bloco de Notas.
