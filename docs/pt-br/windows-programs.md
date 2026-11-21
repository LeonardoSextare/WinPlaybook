# Chamar programas e scripts do Windows

Os programas do `Path` do Windows funcionam nas tarefas que rodam no
`localhost`, e os _scripts_ do projeto são executados de acordo com a extensão,
como no Windows.

## Chamar um programa do Path

Numa tarefa `ansible.builtin.command` ou `ansible.builtin.shell`, chame o
programa pelo nome, com ou sem a extensão:

```yaml
- name: Lista os pull requests abertos
  ansible.builtin.command: gh pr list
  delegate_to: localhost
```

Os programas com as extensões `.com`, `.exe`, `.bat` e `.cmd` funcionam, na
ordem do `Path` e do `PATHEXT`, como no Windows. Os argumentos que são
caminhos, como o `{{ playbook_dir }}`, chegam ao programa como caminhos do
Windows.

!!! warning "Dois cuidados"

    - Quando um nome existe no Windows e no Linux do WinPlaybook, como o `git`
      e o `ssh`, vale o programa do Linux. Para usar o do Windows, inclua a
      extensão: `git.exe`.
    - O Python do Windows só roda com a extensão: `python.exe`.

---

## Chamar um programa no lookup pipe

No `lookup('pipe')`, um comando que começa com um programa do Windows recebe os
argumentos como no Windows, sem que um _shell_ do Linux interprete as aspas e
o `$`:

```yaml
- name: Pega o IP de uma máquina virtual do Hyper-V
  ansible.builtin.set_fact:
    ip_da_vm: >-
      {{ lookup('pipe', 'powershell.exe -NoProfile -Command "(Get-VM teste | Get-VMNetworkAdapter).IPAddresses[0]"') }}
```

Um comando que usa `|`, `&&`, `;`, `<` ou `>` fora das aspas passa pelo `sh`,
como no Linux.

!!! note "No módulo shell"

    O `ansible.builtin.shell` sempre passa o comando pelo `sh` do Linux, como
    no Ansible normal. Para chamar o PowerShell com aspas e `$`, use o
    `ansible.builtin.command` com o `argv`:

    ```yaml
    - name: Mostra o nome do computador
      ansible.builtin.command:
        argv: [powershell.exe, -NoProfile, -Command, "Write-Output $env:COMPUTERNAME"]
      delegate_to: localhost
    ```

---

## Rodar um script do projeto

Um _script_ do projeto é executado de acordo com a extensão, como no Windows:

| Extensão         | Roda com                              |
| ---------------- | ------------------------------------- |
| `.ps1`           | `powershell.exe`                      |
| `.bat` e `.cmd`  | `cmd.exe`                             |
| `.exe` e `.com`  | Diretamente                           |
| `.py` e `.sh`    | O _shebang_ do arquivo, ou o Python do Ansible e o `sh` |

Isso vale também para os arquivos que o Ansible executa, como um inventário
dinâmico ou um arquivo de senha do vault:

```powershell
ansible-playbook -i .\inventario.ps1 --vault-password-file .\senha.bat site.yml
```

Os outros arquivos, como um `senha.txt`, continuam sendo lidos como texto.

---

## Usar o editor do Windows no vault

O `ansible-vault create` e o `ansible-vault edit` abrem o editor definido
na variável `EDITOR` do Windows. Sem essa variável, eles abrem o Bloco de
Notas. Para usar o VS Code:

```powershell
$env:EDITOR = 'code --wait'
ansible-vault edit segredos.yml
```

---

## Chamar um serviço do localhost do Windows

Um serviço que escuta no `localhost` do Windows, como uma API em
desenvolvimento ou um container do Docker Desktop, também responde no
`localhost` das tarefas:

```yaml
- name: Espera a API subir
  ansible.builtin.wait_for:
    port: 8080
  delegate_to: localhost
```
