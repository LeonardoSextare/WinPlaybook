# Seu primeiro playbook

Neste tutorial, você escreve um _playbook_ que configura o seu próprio
Windows: ele cria uma pasta no seu perfil, grava um arquivo nela e mostra a
versão do Windows. No fim, você roda o mesmo _playbook_ de novo e vê que o
Ansible não repete o que já está feito.

!!! info "Antes de começar"

    Você precisa do WinPlaybook [instalado](install.md).

## 1. Ligue o localhost_windows

O `localhost_windows` é o host que representa a sua máquina Windows. Se você
não o ligou na instalação, ligue agora:

```powershell
Enable-WinPlaybookLocalhost
```

!!! note "Administrador"

    O Windows pede a aprovação de administrador. Na primeira vez, o comando pode
    levar alguns minutos.

---

## 2. Crie a pasta do projeto

```powershell
mkdir $HOME\primeiro-playbook
cd $HOME\primeiro-playbook
```

---

## 3. Escreva o playbook

Abra um arquivo novo no Bloco de Notas:

```powershell
notepad site.yml
```

Confirme a criação do arquivo, cole o conteúdo abaixo e salve:

```yaml
- name: Meu primeiro playbook no Windows
  hosts: localhost_windows
  tasks:
    - name: Cria a pasta ola-ansible no meu perfil
      ansible.windows.win_file:
        path: '{{ ansible_facts.user_dir }}\ola-ansible'
        state: directory

    - name: Grava um arquivo na pasta
      ansible.windows.win_copy:
        dest: '{{ ansible_facts.user_dir }}\ola-ansible\leia-me.txt'
        content: Este arquivo foi criado pelo Ansible.

    - name: Mostra a versão do Windows
      ansible.builtin.debug:
        msg: 'Configurei o {{ ansible_facts.os_name }}'
```

---

## 4. Rode o playbook

```powershell
ansible-playbook site.yml
```

O Ansible se conecta ao seu Windows, cria a pasta e o arquivo e mostra a versão
do Windows. O resumo no fim mostra o que mudou:

```text
PLAY RECAP *********************************************************************
localhost_windows          : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Abra a pasta e veja o arquivo:

```powershell
explorer $HOME\ola-ansible
```

---

## 5. Rode de novo

```powershell
ansible-playbook site.yml
```

!!! success "Idempotência"

    Desta vez, o resumo mostra `changed=0`. A pasta e o arquivo já estão como o
    _playbook_ descreve, e o Ansible só faz o que falta.

---

## Próximos passos

- Abra o projeto no VS Code com a [extensão Ansible](vscode.md).
- Configure [servidores por SSH](ssh.md).
- Veja os [recursos do WinPlaybook](features.md).
- Os módulos do Windows estão na documentação da
  [collection ansible.windows](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html).
